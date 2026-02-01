unit AsmTouch;

interface

procedure TouchSequential(P: PByte; Size: Integer);
procedure TouchPageStride(P: PByte; Size: Integer);

implementation

procedure TouchSequential(P: PByte; Size: Integer);
asm
  push esi
  mov  esi, P
  mov  ecx, Size
@@loop:
  mov  al, [esi]
  inc  esi
  dec  ecx
  jnz  @@loop
  pop  esi
end;

procedure TouchPageStride(P: PByte; Size: Integer);
asm
  push esi
  mov  esi, P
  mov  ecx, Size
@@loop:
  mov  al, [esi]
  add  esi, 4096
  sub  ecx, 4096
  jg   @@loop
  pop  esi
end;

end.

