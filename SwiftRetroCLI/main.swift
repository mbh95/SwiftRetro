//
//  main.swift
//  SwiftRetroCLI
//
//  Created by Matt Hammond on 4/8/25.
//

func main() {
    let core = LibretroCore(corePath: "2048_libretro.dylib")!
    core.load()
    core.unload()
}

main()

