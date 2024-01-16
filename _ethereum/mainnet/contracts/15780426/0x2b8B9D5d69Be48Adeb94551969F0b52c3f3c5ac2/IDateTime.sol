// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDateTime {
  /*
   *  Interface for the DateTime contract.
   */
  struct DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }
  function isLeapYear(uint16 year) external pure returns (bool);
  function getYear(uint timestamp) external pure returns (uint16);
  function getMonth(uint timestamp) external pure returns (uint8);
  function getDay(uint timestamp) external pure returns (uint8);
  function getHour(uint timestamp) external pure returns (uint8);
  function getMinute(uint timestamp) external pure returns (uint8);
  function getSecond(uint timestamp) external pure returns (uint8);
  function getWeekday(uint timestamp) external pure returns (uint8);
  function toTimestamp(uint16 year, uint8 month, uint8 day) external pure returns (uint timestamp);
  function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) external pure returns (uint timestamp);
  function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) external pure returns (uint timestamp);
  function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) external pure returns (uint timestamp);
  function parseTimestamp(uint timestamp) external pure returns (IDateTime.DateTime memory dt);
}

// This smart contract is a fork of Piper Merriam's DateTime contract
// which can be found at 0x1a6184cd4c5bea62b0116de7962ee7315b7bcbce

// Below is the original license:

// The MIT License (MIT)

// Copyright (c) 2015 Piper Merriam

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
