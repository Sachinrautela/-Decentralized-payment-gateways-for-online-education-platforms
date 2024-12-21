// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedEducationPayment {

    address public admin;

    struct Course {
        uint256 id;
        string title;
        address instructor;
        uint256 price;
    }
    

    struct Enrollment {
        address student;
        uint256 courseId;
        bool isEnrolled;
    }

    mapping(uint256 => Course) public courses;
    mapping(uint256 => Enrollment[]) public enrollments;
    mapping(address => uint256) public instructorBalances;

    uint256 public nextCourseId;

    event CourseAdded(uint256 courseId, string title, address instructor, uint256 price);
    event CourseRemoved(uint256 courseId);
    event Enrolled(address student, uint256 courseId);
    event FundsWithdrawn(address instructor, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyInstructor(uint256 courseId) {
        require(courses[courseId].instructor == msg.sender, "Not the course instructor");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addCourse(string memory title, uint256 price) external {
        require(price > 0, "Price must be greater than zero");

        courses[nextCourseId] = Course(nextCourseId, title, msg.sender, price);

        emit CourseAdded(nextCourseId, title, msg.sender, price);

        nextCourseId++;
    }

    function removeCourse(uint256 courseId) external onlyInstructor(courseId) {
        delete courses[courseId];
        emit CourseRemoved(courseId);
    }

    function enroll(uint256 courseId) external payable {
        Course memory course = courses[courseId];
        require(course.id == courseId, "Course does not exist");
        require(msg.value == course.price, "Incorrect payment amount");

        Enrollment[] storage courseEnrollments = enrollments[courseId];
        for (uint256 i = 0; i < courseEnrollments.length; i++) {
            require(courseEnrollments[i].student != msg.sender, "Already enrolled");
        }

        courseEnrollments.push(Enrollment({student: msg.sender, courseId: courseId, isEnrolled: true}));

        instructorBalances[course.instructor] += msg.value;

        emit Enrolled(msg.sender, courseId);
    }

    function withdrawFunds() external {
        uint256 balance = instructorBalances[msg.sender];
        require(balance > 0, "No funds to withdraw");

        instructorBalances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(msg.sender, balance);
    }

    function getCourse(uint256 courseId) external view returns (Course memory) {
        return courses[courseId];
    }

    function getEnrollments(uint256 courseId) external view returns (Enrollment[] memory) {
        return enrollments[courseId];
    }
}
