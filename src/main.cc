#include <opencv2/opencv.hpp>
#include <iostream>

int main(void)
{
    std::cout << cv::getBuildInformation();
    cv::VideoCapture cap;
    cap.open("http://77.243.103.105:8081/mjpg/video.mjpg", cv::CAP_FFMPEG);
    cv::Mat buf;
    std::string filename = "img_0.png";
    for (int i = 0; i < 10; i++)
    {
        bool status = cap.read(buf);
        cv::imwrite(filename, buf);
        filename[4]++;
    }
}