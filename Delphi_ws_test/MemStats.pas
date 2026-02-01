unit MemStats;

interface

uses
  Winapi.Windows, PsAPI;

type
  TMemSnapshot = record
    WorkingSet: UInt64;
    PrivateBytes: UInt64;
    PageFaults: UInt64;
    AvailPhys: UInt64;
  end;

function CaptureMemory: TMemSnapshot;

implementation

function CaptureMemory: TMemSnapshot;
var
  pmc: PROCESS_MEMORY_COUNTERS_EX;
  ms: TMemoryStatusEx;
begin
  pmc.cb := SizeOf(pmc);
  GetProcessMemoryInfo(GetCurrentProcess, @pmc, SizeOf(pmc));

  ms.dwLength := SizeOf(ms);
  GlobalMemoryStatusEx(ms);

  Result.WorkingSet   := pmc.WorkingSetSize;
  Result.PrivateBytes := pmc.PrivateUsage;
  Result.PageFaults   := pmc.PageFaultCount;
  Result.AvailPhys    := ms.ullAvailPhys;
end;

end.

