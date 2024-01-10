// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";

contract Descriptor is Ownable {
  // attribute svgs
  string internal constant BEGINNING =
    "<image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEA";
  string internal constant END = "'/>";
  string internal constant F = '<g filter="url(#a)">';
  string internal constant V = '<g class="vibe">';
  string internal constant F_E = "</g>";
  string internal constant DEFS =
    '<defs><filter id="a"><feTurbulence baseFrequency=".01" type="fractalNoise" numOctaves="7" seed="3"><animate attributeName="baseFrequency" dur="0.02s" values="0.015; 0.015; 0.015; 0.025; 0.03; 0.025; 0.02; 0.015" repeatCount="indefinite"/></feTurbulence><feDisplacementMap in="SourceGraphic" scale="10" yChannelSelector="A"/></filter></defs>';

  string[] public backs;
  string[] public mouths;
  string[] public accessories;
  string[] public backgrounds;
  string[] public bottoms;
  string[] public clothes;
  string[] public eyes;
  string[] public headgears;
  string[] public legendaries;

  function legendariesLengthCheck() public view returns(uint) {  
        uint x = legendaries.length;
        return x; 
    } 

  function _addBack(string calldata _trait) internal {
    backs.push(_trait);
  }

  function _addMouth(string calldata _trait) internal {
    mouths.push(_trait);
  }

  function _addAccessory(string calldata _trait) internal {
    accessories.push(_trait);
  }

  function _addBackground(string calldata _trait) internal {
    backgrounds.push(_trait);
  }

  function _addBottom(string calldata _trait) internal {
    bottoms.push(_trait);
  }

  function _addClothes(string calldata _trait) internal {
    clothes.push(_trait);
  }

  function _addEyes(string calldata _trait) internal {
    eyes.push(_trait);
  }

  function _addHeadgear(string calldata _trait) internal {
    headgears.push(_trait);
  }

  function _addLegendary(string calldata _trait) internal {
    legendaries.push(_trait);
  }

  // calldata input format: ["trait1","trait2","trait3",...]
  function addManyBacks(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addBack(_traits[i]);
    }
  }

  function addManyMouths(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addMouth(_traits[i]);
    }
  }

  function addManyAccessories(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addAccessory(_traits[i]);
    }
  }

  function addManyBackgrounds(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addBackground(_traits[i]);
    }
  }

  function addManyBottoms(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addBottom(_traits[i]);
    }
  }

  function addManyClothes(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addClothes(_traits[i]);
    }
  }

  function addManyEyes(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addEyes(_traits[i]);
    }
  }

  function addManyHeadgears(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addHeadgear(_traits[i]);
    }
  }

  function addManyLegendaries(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addLegendary(_traits[i]);
    }
  }  

  function clearBacks() external onlyOwner {
    delete backs;
  }

  function clearMouths() external onlyOwner {
    delete mouths;
  }

  function clearAccessories() external onlyOwner {
    delete accessories;
  }

  function clearBackgrounds() external onlyOwner {
    delete backgrounds;
  }

  function clearBottoms() external onlyOwner {
    delete bottoms;
  }

  function clearClothes() external onlyOwner {
    delete clothes;
  }

  function clearEyes() external onlyOwner {
    delete eyes;
  }

  function clearHeadgears() external onlyOwner {
    delete headgears;
  }

  function clearLegendaries() external onlyOwner {
    delete legendaries;
  }  

  function renderBack(uint256 _trait) public view returns (bytes memory) {
    //hellhog
    if (_trait != 22) {
      return abi.encodePacked(V, BEGINNING, string(backs[_trait]), END, F_E);
    } else {
      return abi.encodePacked(V, F, BEGINNING, backs[_trait], END, F_E, F_E, DEFS);
    }
  }

  function renderMouth(uint256 _mouth) external view returns (bytes memory) {
    //laser
    if (_mouth != 24) {
      return abi.encodePacked(V, BEGINNING, mouths[_mouth], END, F_E);
    } else {
      return abi.encodePacked(V, F, BEGINNING, mouths[_mouth], END, F_E, F_E, DEFS);
    }
  }

  function renderAccessory(uint256 _accessory)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(BEGINNING, accessories[_accessory], END);
  }

  function renderBackground(uint256 _background)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(backgrounds[_background]);
  }

  function renderBottom(uint256 _bottom) external view returns (bytes memory) {
    return abi.encodePacked(BEGINNING, bottoms[_bottom], END);
  }

  function renderClothes(uint256 _clothes)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(BEGINNING, clothes[_clothes], END);
  }

  function renderEyes(uint256 _eyes) external view returns (bytes memory) {
    //laser
    if (_eyes != 33) {
      return abi.encodePacked(V, BEGINNING, eyes[_eyes], END, F_E);
    } else {
      return abi.encodePacked(V, F, BEGINNING, eyes[_eyes], END, F_E, F_E, DEFS);
    }
  }

  function renderHeadgear(uint256 _headgear)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(V, BEGINNING, headgears[_headgear], END, F_E);
  }

  function renderLegendary(uint256 _legendary)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(legendaries[_legendary]);
  }
}


