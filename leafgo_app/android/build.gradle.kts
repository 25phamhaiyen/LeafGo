allprojects {
    repositories {
        google()
        mavenCentral()
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
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        val javaTask = project.tasks.findByName("compileDebugJavaWithJavac") as? JavaCompile
            ?: project.tasks.withType<JavaCompile>().firstOrNull()
            
        if (javaTask != null) {
            val target = javaTask.targetCompatibility
            if (target != null) {
                compilerOptions {
                    if (target == "17" || target == "VERSION_17" || target.contains("17")) {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                    } else if (target == "11" || target == "VERSION_11" || target.contains("11")) {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
                    } else {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
