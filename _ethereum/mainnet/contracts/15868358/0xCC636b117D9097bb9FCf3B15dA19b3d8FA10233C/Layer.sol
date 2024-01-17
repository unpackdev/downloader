// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";

abstract contract Layer is Ownable {
  /// @notice address of the NFT contract that combines all of the individual layers together
  address public composableNFTAddress;

  /// @notice cost to change color - 0.007 ETH
  uint256 public colorChangePrice = 7000000000000000;

  /// @notice a layer can be either a default or optional layer. The former are selected at time of mint. The latter are optional accessories
  bool public isDefaultLayer;

  /// @notice Records the selected layer option for each individual NFT
  mapping (uint256 => OptionSelection) public selectedOption;

  /// @notice array holding all the potential options for an individual layer
  Option[] public layerOptions;

  /// @notice name of this individual layer
  string public layerName;

  /// @notice an NFT's selected option for an individual layer
  struct OptionSelection {
    uint256 optionNumber;
    string color1Hex;
    string color2Hex;
  }

  /// @notice data of each potential optional for an individual layer
  struct Option {
    string svg;
    string value;
    string defaultColor1Hex;
    string defaultColor2Hex;
    uint256 rarityStart;
    uint256 rarityEnd;
  }

  /// @notice bypass block gas limit error for large SVG files by splitting the SVG string into multiple transactions 
  /// @param optionIndex index of the option
  /// @param svgStringToConcatenate svg string to concatenate to the end of the existing SVG string
  function addOptionsByConcatenation (
    uint256 optionIndex,
    string memory svgStringToConcatenate
  ) public onlyOwner
  {
    require(layerOptions.length > optionIndex,"Option Index Undefined");
    layerOptions[optionIndex].svg = string.concat(layerOptions[optionIndex].svg, svgStringToConcatenate);
  }

  /// @notice adds an option for an individual layer
  /// @param option struct corresponding to an layer option
  function addOptions (
    Option memory option
  ) public onlyOwner
  {
    // This ensures that the first option is a null item
    if(layerOptions.length == 0) {
      layerOptions.push(Option({
        svg: "",
        value: "",
        defaultColor1Hex: "",
        defaultColor2Hex: "",
        rarityStart: 1000,
        rarityEnd: 1000
      }));
    }
    layerOptions.push(option);
  }

  /// @notice returns the attributes metadata for this individual layer
  /// @param tokenId the selected NFT
  function getOptionMetadataByTokenId (
    uint256 tokenId
  )
    external
    virtual
    view
    returns (string memory)
  {
    string memory value = layerOptions[selectedOption[tokenId].optionNumber].value;
    if(bytes(value).length == 0) return "";

    return string.concat(
      '{ "trait_type": "',
      layerName,
      '", "value": "',
      value,
      '" }'
    );
  }

  /// @notice returns the SVG image for this individual layer
  /// @param tokenId the selected NFT
  function renderOptionByTokenId(
    uint256 tokenId
  )
    external
    virtual
    view
    returns (string memory)
  {
    string memory svgOption = layerOptions[selectedOption[tokenId].optionNumber].svg;
    if(bytes(svgOption).length == 0) return "";

    string memory color2Hex = selectedOption[tokenId].color2Hex;
    string memory secondColorVar = string.concat(
      '<linearGradient id="',
      layerName,
      '-secondColor',
      '" x1="0" x2="1" y1="0" y2="0"><stop stop-color="',
      color2Hex,
      '" offset="0"></stop><stop stop-color="',
      color2Hex,
      '" offset="1"></stop></linearGradient>'
    );
    
    return string(abi.encodePacked(
      '<g',
      ' id="',
      layerName,
      '"',
      ' color="',
      selectedOption[tokenId].color1Hex,
      '">',
      bytes(color2Hex).length > 1 ? secondColorVar : '',
      svgOption,
      '</g>'
      ));
  }


  /// @notice Selects the layer option for this individual layer
  /// @param tokenID the selected NFT
  /// @param randomNumber used to select the NFT based on rarity
  /// @param forceZeroOption Make this layer empty
  function selectOption ( 
    uint256 tokenID,
    uint256 randomNumber,
    bool forceZeroOption
  ) public
  returns (uint256){
    if(isDefaultLayer){
      require(msg.sender == composableNFTAddress, "Only NFT Contract can select option on Default Layer");
    } else {
      require(IERC721(composableNFTAddress).ownerOf(tokenID) == msg.sender, "Only NFT owner can call");
    }

    // Make sure every layer has a default Zero option that is an empty layer
    // rarityStart & rarityEnd should both be 0, so that is is impossible to be selected unless manually set due to specific if-then logic
    if(forceZeroOption == true){
        selectedOption[tokenID] = OptionSelection({
          optionNumber: 0,
          color1Hex: layerOptions[0].defaultColor1Hex,
          color2Hex: layerOptions[0].defaultColor2Hex
        });
        return 0;
    }

    for(uint256 i = 0; i < layerOptions.length; i++){
      if(
        randomNumber >= layerOptions[i].rarityStart && 
        randomNumber < layerOptions[i].rarityEnd
      ) {
        selectedOption[tokenID] = OptionSelection({
          optionNumber: i,
          color1Hex: layerOptions[i].defaultColor1Hex,
          color2Hex: layerOptions[i].defaultColor2Hex
        });
        return i;
      }
    }
    return 99; // should never reach here
  }

  /// @notice Changes the color of an option for this individual layer
  /// @param tokenId the selected NFT
  /// @param color1Hex Hex String of the 1st color
  /// @param color2Hex Hex String of the 2nd color
  function setColor(
    uint256 tokenId,
    string memory color1Hex,
    string memory color2Hex
  ) public payable
  {
    require(IERC721(composableNFTAddress).ownerOf(tokenId) == msg.sender, "You are not the owner");
    require(msg.value == colorChangePrice);

    if(bytes(color1Hex).length > 1){
      selectedOption[tokenId].color1Hex = color1Hex;
    }

    if(bytes(color2Hex).length > 1){
      selectedOption[tokenId].color2Hex = color2Hex;
    }
  }

  /// @notice Transfers ETH collected from layer color changes
  function collectColorChangeFee()
    public
    onlyOwner
  {
    payable(msg.sender).transfer(address(this).balance);
  }
}
