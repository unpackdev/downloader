// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Book {
    // Use a mapping instead of an array to store chapters
    mapping(uint => string) public chapters;
    uint public chapterCount;

    // Function to add a new chapter
    function addChapter(string memory _text) public {
        chapters[chapterCount] = _text;
        chapterCount++;
    }

    // Function to retrieve a chapter's text by index
    function getChapter(uint index) public view returns (string memory) {
        require(index < chapterCount, "Chapter does not exist.");
        return chapters[index];
    }
}