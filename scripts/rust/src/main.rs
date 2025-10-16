use anyhow::{Context, Result};
use image::DynamicImage;
use indicatif::{ProgressBar, ProgressStyle};
use std::path::Path;
use walkdir::WalkDir;
use webp::Encoder;

// 🔥 ЗАХАРДКОЖЕННЫЕ ПАРАМЕТРЫ 🔥
const INPUT_DIR: &str = r"D:\photo_to_sort";           // Папка с NEF/JPG файлами
const OUTPUT_DIR: &str = r"D:\ergrwg";                 // Папка для WebP файлов  
const WEBP_QUALITY: u8 = 85;                           // Качество WebP (0-100)
const RECURSIVE: bool = false;                         // Обрабатывать подпапки?

fn main() -> Result<()> {
    println!("🚀 NEF/JPG to WebP Converter");
    println!("📁 Input: {}", INPUT_DIR);
    println!("📁 Output: {}", OUTPUT_DIR);
    println!("🎨 Quality: {}%", WEBP_QUALITY);
    println!("🔄 Recursive: {}", RECURSIVE);
    
    let separator = "─".repeat(50);
    println!("{}\n", separator);
    
    // Проверяем входную папку
    let input_path = Path::new(INPUT_DIR);
    if !input_path.exists() {
        return Err(anyhow::anyhow!("Input directory '{}' does not exist!", INPUT_DIR));
    }
    
    // Создаем выходную папку
    std::fs::create_dir_all(OUTPUT_DIR)?;
    
    // Находим все NEF и JPG файлы
    let image_paths = find_image_files(INPUT_DIR, RECURSIVE)?;
    
    if image_paths.is_empty() {
        println!("❌ No NEF or JPG files found in '{}'", INPUT_DIR);
        return Ok(());
    }
    
    println!("📸 Found {} images to process", image_paths.len());
    println!("{}\n", separator);
    
    // 🔥 ПРОГРЕСС-БАР 🔥
    let pb = ProgressBar::new(image_paths.len() as u64);
    let style = ProgressStyle::default_bar()
        .template("{msg} {spinner:.green} [{bar:60.cyan/blue}] {pos}/{len} ({eta}) {percent}%")?
        .progress_chars("█▓░")
        .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]);
    pb.set_style(style);
    pb.set_message(format!("🔄 Converting images ({}% quality)", WEBP_QUALITY));
    
    // Последовательная обработка с прогрессом
    let mut results = Vec::new();
    for (index, path) in image_paths.iter().enumerate() {
        // Обновляем прогресс-бар
        pb.set_position(index as u64);
        
        // Устанавливаем имя текущего файла
        if let Some(filename) = path.file_name().and_then(|s| s.to_str()) {
            pb.set_message(format!("🔄 Processing: {}", filename));
        }
        
        let result = process_single_image(path, OUTPUT_DIR, WEBP_QUALITY);
        pb.inc(1);
        results.push(result);
    }
    
    // Завершаем прогресс-бар
    pb.finish_with_message("✅ Conversion complete!");
    
    // Подсчитываем результаты
    let (success, failed): (Vec<_>, Vec<_>) = results
        .into_iter()
        .partition(Result::is_ok);
    
    let success_count = success.len();
    let failed_count = failed.len();
    
    println!("\n🎉 === FINAL RESULTS ===");
    println!("✅ Successfully converted: {}", success_count);
    println!("❌ Failed: {}", failed_count);
    if !image_paths.is_empty() {
        println!("📊 Success rate: {:.1}%", (success_count as f32 / image_paths.len() as f32) * 100.0);
    }
    
    if !failed.is_empty() {
        println!("\n📋 Failed files:");
        for err in failed {
            if let Err(e) = err {
                println!("  ❌ {}", e);
            }
        }
    } else {
        println!("✨ All files processed successfully!");
    }
    
    println!("\n📁 WebP files saved to: {}", OUTPUT_DIR);
    Ok(())
}

fn find_image_files(input_dir: &str, recursive: bool) -> Result<Vec<std::path::PathBuf>> {
    let walker = WalkDir::new(input_dir)
        .follow_links(false)
        .max_depth(if recursive { std::usize::MAX } else { 1 })
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| {
            let ext = e.path().extension().and_then(|s| s.to_str());
            matches!(
                ext, 
                Some("NEF") | Some("nef") | 
                Some("JPG") | Some("jpg") | 
                Some("JPEG") | Some("jpeg")
            )
        });
    
    let paths: Vec<std::path::PathBuf> = walker.map(|e| e.into_path()).collect();
    Ok(paths)
}

fn process_single_image(
    input_path: &std::path::Path, 
    output_dir: &str, 
    quality: u8
) -> Result<()> {
    let filename = input_path
        .file_stem()
        .and_then(|s| s.to_str())
        .context("Invalid filename")?;
    
    let output_path = std::path::Path::new(output_dir)
        .join(format!("{}.webp", filename));
    
    // Пропускаем уже существующие файлы
    if output_path.exists() {
        return Ok(());
    }
    
    // Загружаем изображение
    let img = load_image(input_path).context(format!(
        "Failed to load: {}",
        input_path.display()
    ))?;
    
    // Конвертируем в WebP
    convert_to_webp(&img, &output_path, quality).context(format!(
        "Failed to convert {} to WebP",
        input_path.display()
    ))?;
    
    Ok(())
}

fn load_image(path: &std::path::Path) -> Result<DynamicImage> {
    let img = image::open(path)
        .with_context(|| format!("Cannot open image: {}", path.display()))?;
    
    // Конвертируем в RGB если нужно (для единообразия)
    Ok(img.to_rgb8().into())
}

fn convert_to_webp(
    img: &DynamicImage, 
    output_path: &std::path::Path, 
    quality: u8
) -> Result<()> {
    // ✅ ИСПРАВЛЕНО: Encoder::from_image возвращает Result<Encoder, &str>
    let encoder = match Encoder::from_image(img) {
        Ok(encoder) => encoder,
        Err(e) => return Err(anyhow::anyhow!("Failed to create WebP encoder: {}", e)),
    };
    
    let webp = encoder.encode(quality as f32);
    
    std::fs::write(output_path, &*webp)
        .with_context(|| format!("Failed to write: {}", output_path.display()))?;
    
    Ok(())
}