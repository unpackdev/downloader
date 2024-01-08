// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BubbleGumState.sol";
import "./Base64.sol";

contract BubbleGumMeta is BubbleGumState {
  using Counters for Counters.Counter;
  constructor(string memory _name, string memory _symbol, uint _launchAt) BubbleGumState(_name, _symbol, _launchAt) {}

  function _taste(uint8 _flavors, uint8 _flavor) internal pure returns (bool) {
    require(_flavor < 8, "Only 8 flavors exist.");
    bool isTasted = _flavors & (1 << _flavor) == 2 ** _flavor;

    return isTasted;
  }

  function _tokenImage(uint _id) internal view returns (string memory) {
    bytes memory img = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><linearGradient id="a" gradientTransform="rotate(45)"><stop offset="0" stop-color="red"/><stop offset="0.2" stop-color="#ff0"/><stop offset="0.4" stop-color="lime"/><stop offset="0.6" stop-color="aqua"/><stop offset="0.8" stop-color="blue"/><stop offset="1" stop-color="#f0f"/></linearGradient><clipPath id="b"><circle cx="50" cy="50" r="45"/></clipPath><radialGradient id="c" r="45" gradientUnits="userSpaceOnUse"><stop offset="0" stop-opacity="0"/><stop offset="0.6" stop-opacity="0"/><stop offset="0.8" stop-opacity="0.3"/><stop offset="1" stop-opacity="0.7"/></radialGradient><linearGradient id="d" gradientTransform="rotate(90)"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="#fff0"/></linearGradient></defs>';
    if (meta[_id].intensity == 8) {
      // Add rainbow background for bubble gums with maximum flavor intensity.
      img = abi.encodePacked(img, '<rect width="100" height="100" style="fill:url(#a)"/>');
    }
    img = abi.encodePacked(img, '<circle cx="50" cy="50" r="45"/><g style="clip-path:url(#b)">');
    if (_taste(meta[_id].flavor, 0)) img = abi.encodePacked(img, '<rect x="-37" y="21.1" width="120" height="10.4" transform="translate(-11.8 24) rotate(-45)" style="fill:red"/>');
    if (_taste(meta[_id].flavor, 1)) img = abi.encodePacked(img, '<rect x="-22.5" y="35.6" width="120" height="10.4" transform="translate(-17.8 38.5) rotate(-45)" style="fill:#e91e63"/>');
    if (_taste(meta[_id].flavor, 2)) img = abi.encodePacked(img, '<rect x="-29.8" y="28.3" width="120" height="10.4" transform="translate(-14.8 31.2) rotate(-45)" style="fill:#4a148c"/>');
    if (_taste(meta[_id].flavor, 3)) img = abi.encodePacked(img, '<rect x="-15.2" y="42.8" width="120" height="10.4" transform="translate(-20.8 45.7) rotate(-45)" style="fill:#2196f3"/>');
    if (_taste(meta[_id].flavor, 4)) img = abi.encodePacked(img, '<rect x="-8" y="50.1" width="120" height="10.4" transform="translate(-23.8 53) rotate(-45)" style="fill:#4caf50"/>');
    if (_taste(meta[_id].flavor, 5)) img = abi.encodePacked(img, '<rect x="6.5" y="64.6" width="120" height="10.4" transform="translate(-29.9 67.5) rotate(-45)" style="fill:#ffeb3b"/>');
    if (_taste(meta[_id].flavor, 6)) img = abi.encodePacked(img, '<rect x="-0.7" y="57.4" width="120" height="10.4" transform="translate(-26.8 60.3) rotate(-45)" style="fill:#ff9800"/>');
    if (_taste(meta[_id].flavor, 7)) img = abi.encodePacked(img, '<rect x="13.8" y="71.9" width="120" height="10.4" transform="translate(-32.9 74.8) rotate(-45)" style="fill:#fff"/>');

    img = abi.encodePacked(img, '</g><path d="M95,50A43.5,43.5,0,0,1,81.9,81.9,43.9,43.9,0,0,1,50,95,43.5,43.5,0,0,1,18.1,81.9,43.5,43.5,0,0,1,5,50,43.5,43.5,0,0,1,18.1,18.1,43.9,43.9,0,0,1,50,5,44.3,44.3,0,0,1,81.9,18.1,43.9,43.9,0,0,1,95,50Z" style="fill:url(#c)"/><path d="M31.6,16.1c9.3.2,10.5,4.8,3.5,13.6S22.6,42.2,19.8,39.1s-2.3-7.3.7-13.6S27.2,15.8,31.6,16.1Z" style="fill:#fff;opacity:0.84"/><path d="M20.8,44.8c2.3.2,3,2,2.1,5.2s-2.2,4.3-3.8,3.1a4.7,4.7,0,0,1-1.7-5.2C18,45.3,19.2,44.3,20.8,44.8Z" style="fill:#fff;opacity:0.84"/><path d="M50,6.5c19.6,0,35.6,12.7,35.6,28.3S69.6,63.1,50,63.1,14.4,50.5,14.4,34.8,30.4,6.5,50,6.5Z" style="fill:url(#d)"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="font-size:28px;font-family:sans-serif;letter-spacing:-1px;fill:#fff;stroke:#000;stroke-width:.5px">');
    img = abi.encodePacked(img, Strings.toString(meta[_id].size));
    img = abi.encodePacked(img, '</text></svg>');

    return string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(img)));
  }

  /**
   * Time until launch.
   */
  function untilLaunch() public view returns (uint) {
    return block.timestamp < launchAt ? (launchAt - block.timestamp) : 0;
  }

  /**
   * Token URI
   * Returns token metadata with generated SVG.
   */
  function tokenURI(uint256 _id) override public view returns (string memory) {
    require(_id <= _ids.current(), "Token doesn't exist.");

    bytes memory _out = abi.encodePacked(
      '{"name":"Bubble Gum Game #',
      Strings.toString(_id),
      '","description":"',
      DESCRIPTION,
      '","image":"',
      _tokenImage(_id),
      '","attributes":[{"trait_type":"Size","value":"',
      Strings.toString(meta[_id].size),
      '"},{"trait_type":"Intensity","value":"',
      Strings.toString(meta[_id].intensity),
      '"}'
    );

    _out = abi.encodePacked(_out,
      meta[_id].isGenesis ? ',{"value":"Genesis"}' : '',
      _taste(meta[_id].flavor, 0) ? ',{"value":"Strawberry"}' : '',
      _taste(meta[_id].flavor, 1) ? ',{"value":"Watermelon"}' : '',
      _taste(meta[_id].flavor, 2) ? ',{"value":"Grape"}' : '',
      _taste(meta[_id].flavor, 3) ? ',{"value":"Blueberry"}' : ''
    );

    _out = abi.encodePacked(_out,
      _taste(meta[_id].flavor, 4) ? ',{"value":"Lime"}' : '',
      _taste(meta[_id].flavor, 5) ? ',{"value":"Pineapple"}' : '',
      _taste(meta[_id].flavor, 6) ? ',{"value":"Orange"}' : '',
      _taste(meta[_id].flavor, 7) ? ',{"value":"Mint"}' : ''
      ']}'
    );

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(_out)));
  }
}