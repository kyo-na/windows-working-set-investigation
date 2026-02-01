(module
  ;; 1 page 初期、最大 8192 pages = 512MB
  (memory (export "memory") 1 8192)

  (func (export "grow") (param $pages i32) (result i32)
    local.get $pages
    memory.grow
  )

  (func (export "touch") (param $offset i32)
    local.get $offset
    i32.const 1
    i32.store8
  )
)
