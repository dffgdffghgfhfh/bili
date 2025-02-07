package com.ruoyi.business.controller;

import com.ruoyi.business.service.MediaService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletResponse;
import java.io.*;

/**
 * 文件上传临时接口
 */
@RestController
@RequestMapping("/api")
public class FileController {
    private String FILE_PATH = "D:\\tmpfile\\";

    @PostMapping("/upload")
    public String uploadFile(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return "请选择要上传的文件";
        }
        try {
            // 获取文件名
            String fileName = file.getOriginalFilename();
            // 文件存储路径
            String filePath = FILE_PATH + fileName;

            // 将文件保存到指定路径
            File dest = new File(filePath);
            file.transferTo(dest);

            return "文件上传成功：" + dest.getName();
        } catch (IOException e) {
            e.printStackTrace();
            return "文件上传失败：" + e.getMessage();
        }
    }

    @GetMapping("/download")
    public void downloadFile(HttpServletResponse response, @RequestParam("fileName") String fileName) {
        File file = new File(FILE_PATH + fileName);
        if (!file.exists()) {
            return;
        }

        try (InputStream inputStream = new FileInputStream(file);
             OutputStream outputStream = response.getOutputStream()) {

            // 设置响应头
            response.setContentType("application/octet-stream");
            response.setHeader("Content-Disposition", "attachment; filename=" + file.getName());

            // 读取文件内容并写入响应
            byte[] buffer = new byte[1024];
            int len;
            while ((len = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, len);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
