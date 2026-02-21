allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// FIX: Automatically add namespace to plugins that lack it for AGP 8+
subprojects {
    if (project.name != "app") {
        afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            // Set compileSdk for Android modules
            android.compileSdkVersion(35)
            if (android.namespace == null) {
                val defaultNamespace = "com.makhzani." + project.name.replace("-", ".")
                android.namespace = defaultNamespace
                println("Setting missing namespace for ${project.name} to $defaultNamespace")
            }
        }
    }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
