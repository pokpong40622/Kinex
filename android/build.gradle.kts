allprojects {
    repositories {
        google()
        mavenCentral()
        // SPIKE — flutter_embed_unity: required so the app module can resolve
        // the .aar libraries that Unity's exported unityLibrary module ships in its libs/ folder.
        flatDir {
            dirs(file("${project(":unityLibrary").projectDir}/libs"))
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
