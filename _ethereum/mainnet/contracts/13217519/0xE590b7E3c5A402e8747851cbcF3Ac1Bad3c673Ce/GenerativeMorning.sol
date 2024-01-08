// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";

////////////////////
// good morning ☀️ //
////////////////////
contract GenerativeMorning is ERC721, Ownable {

    using Strings for uint;

    uint public sunrise; // epoch time in seconds for first sunrise
    bool public revealedOnOS;
    string public realDescription;
    string public twitterGMReceiver;
    string public sayItBackMessage;
    uint private dayLength = 43200; // in seconds

    event SayItBack(address sayer, string message, string receiver);

    constructor(uint inputSunrise, string memory receiver, string memory sayItBackMessageInput, string memory realDescriptionInput) ERC721("Generative Morning", "gm") {
      revealedOnOS = false;
      twitterGMReceiver = receiver;
      sayItBackMessage = sayItBackMessageInput;
      realDescription = realDescriptionInput;
      sunrise = inputSunrise;
      _safeMint(msg.sender, 1);
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
      if (revealedOnOS) {
        return realTokenURI();
      }

      return hiddenTokenURI();
    }

    function hiddenTokenURI() private pure returns (string memory) {
      return string(abi.encodePacked(
        'data:application/json;utf8,',
        '{"name":"Generative Morning",',
        '"description":"gm at generativemorning.eth.link",',
        '"image":"',
            _generateHiddenImage(),
        '", "attributes":[',
            _generateHiddenMetadata(),
        ']',
      '}'));
    }

    function realTokenURI() public view returns (string memory) {
      return string(abi.encodePacked(
        'data:application/json;utf8,',
        '{"name":"Generative Morning",',
        '"description":"',
            realDescription,
        '",',
        '"image":"',
            _generateRealImage(),
        '", "attributes":[',
            _generateRealMetadata(),
        ']',
      '}'));
    }

    function _generateHiddenImage() private pure returns (string memory) {
      return "data:image/svg+xml;utf8,<svg viewBox='0 0 400 400' width='400' height='400' xmlns='http://www.w3.org/2000/svg'><text x='50%' y='50%' style='font:700 30px sans-serif' text-anchor='middle' dominant-baseline='middle'>gm</text></svg>";
    }

    function _generateHiddenMetadata() private pure returns (string memory) {
      return _wrapTrait("good", "morning");
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function isCurrentOwner(address account) private view returns (bool) {
      return balanceOf(account) == 1;
    }

    function isDayTime() public view returns (bool) {
      uint time = block.timestamp;
      uint timeSinceSunrise = time - sunrise;
      uint percentOfTwelve = (100 * timeSinceSunrise / dayLength);
      bool isDay = (percentOfTwelve / 100) % 2 == 0;
      return isDay;
    }

    function _generateRealImage() private view returns (string memory) {
      uint time = block.timestamp;
      uint timeSinceSunrise = time - sunrise;
      uint percentOfTwelve = (100 * timeSinceSunrise / dayLength);

      if (!isDayTime()) {
        return "data:image/svg+xml;utf8,<svg viewBox='0 0 400 400' width='400' height='400' fill='none' xmlns='http://www.w3.org/2000/svg'><path style='fill:#040348' d='M0 0h400v280H0z'/><path style='fill:#1b1e23' d='M0 280h400v120H0z'/><path d='M300 20a30 30 1 0 1 0 60 40 40 1 0 0 0-60z' fill='#fff' style='transform:rotate(-30deg);transform-origin:350px 40px'/></svg>";
      }

      if (percentOfTwelve > 100) {
        percentOfTwelve = percentOfTwelve % 100;
      }

      uint xBase = 400;
      uint yBase = 280;

      uint xMov = (xBase * percentOfTwelve) / 100;
      uint yMov = (120 * yBase * percentOfTwelve) / 10000;

      if (percentOfTwelve > 50) {
        yMov = (120 * yBase * (100 - percentOfTwelve)) / 10000;
      }

      uint finalX = xMov;
      uint finalY = yBase - yMov;

      return string(abi.encodePacked(
          "data:image/svg+xml;utf8,<svg viewBox='0 0 400 400' width='400' height='400' fill='none' xmlns='http://www.w3.org/2000/svg'><path style='fill:#87cefa' d='M0 0h400v280H0z'/>",
          "<circle cx='",
          finalX.toString(),
          "' cy='",
          finalY.toString(),
          "' r='20' style='fill:#e29f05'/>",
          _getSunLine(finalX, finalY, 0),
          _getSunLine(finalX, finalY, 45),
          _getSunLine(finalX, finalY, 90),
          _getSunLine(finalX, finalY, 135),
          _getSunLine(finalX, finalY, 180),
          _getSunLine(finalX, finalY, 225),
          _getSunLine(finalX, finalY, 270),
          _getSunLine(finalX, finalY, 315),
          "<path style='fill:#a82f01' d='M0 280h400v120H0z'/></svg>"
      ));

    }

    function _getSunLine(uint x, uint y, uint rotate) private pure returns (string memory) {
      return string(abi.encodePacked(
        "<path stroke='#e29f05' style='transform:rotate(",
        rotate.toString(),
        "deg);transform-origin:",
        x.toString(),
        "px ",
        y.toString(),
        "px' d='M",
        x.toString(),
        " ",
        (y-25).toString(),
        "V",
        (y-35).toString(),
        "' stroke-width='5'/>"
      ));
    }

    function _generateRealMetadata() private view returns (string memory) {
      return string(abi.encodePacked(
        _wrapTrait("good", "morning"),
        ',',
        _wrapTrait("owner", string(abi.encodePacked("@", twitterGMReceiver)))
      ));
    }

    function setRealDescription(string memory description) public {
      require(isCurrentOwner(msg.sender), 'Only owner can change description.');
      realDescription = description;
    }

    function setSunrise(uint sunriseTime) public {
      require(isCurrentOwner(msg.sender), 'Only owner can change sunrise.');
      sunrise = sunriseTime;
    }

    function setDayLength(uint dayLengthInput) public {
      require(isCurrentOwner(msg.sender), 'Only owner can change day length.');
      dayLength = dayLengthInput;
    }

    function setSayItBackMessage(string memory message) public {
      require(isCurrentOwner(msg.sender), 'Only owner can change say it back message.');
      sayItBackMessage = message;
    }

    function sayItBack() public {
      require(!isCurrentOwner(msg.sender), "You can't say it back to yourself");
      emit SayItBack(msg.sender, sayItBackMessage, twitterGMReceiver);
    }

    function revealOnOS() public {
      require(isCurrentOwner(msg.sender), 'Only owner can reveal on OS.');
      revealedOnOS = true;
    }

    function hideOnOS() public {
      require(isCurrentOwner(msg.sender), 'Only owner can hide on OS.');
      revealedOnOS = false;
    }
}
