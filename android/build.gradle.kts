// 🔥 Khối buildscript — cần cho Google Services
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// 🔥 Repositories cho toàn bộ project
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ⚡ Cấu hình thư mục build mới (Flutter dùng để tránh conflict)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔥 Đảm bảo module :app build trước khi các module khác evaluate
subprojects {
    project.evaluationDependsOn(":app")
}

// Lệnh clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
