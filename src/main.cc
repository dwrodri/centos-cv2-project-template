#include <opencv2/opencv.hpp>
#include <iostream>

int main(void)
{
    cv::VideoCapture cap;
    cap.open("http://77.243.103.105:8081/mjpg/video.mjpg");
    cv::Mat buf;
    while (true)
    {
        bool status = cap.read(buf);
        cv::imshow("testing", buf);
        cv::waitKey(5);
    }
}