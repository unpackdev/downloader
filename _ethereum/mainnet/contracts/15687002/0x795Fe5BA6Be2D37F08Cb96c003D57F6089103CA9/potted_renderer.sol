// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./base64.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./potted_types.sol";

interface PPdata {
    function getAllPotted() external view returns (PottedTypes.Potted[] memory);
    function getAllBranch() external view returns (PottedTypes.Branch[] memory);
    function getAllBlossom() external view returns (PottedTypes.Blossom[] memory);
    function getAllBg() external view returns (PottedTypes.Bg[] memory);
    function getPottedImages() external view returns (bytes[] memory);
    function getBranchImages() external view returns (bytes[] memory);
    function getBlossomImages() external view returns (bytes[] memory);
    function getBgImages() external view returns (bytes[] memory);
    function getUnreveal() external view returns (bytes[] memory);
}

contract PPRenderer is Ownable {
    address public coreContract;
    PPdata public ppData = PPdata(0xEA5fdE024930A9ac6DAD8AB8e7FA2B17512754e1);
    uint[] pottedCoverage = [0,1,2,3,4,5,6,7,9,10,11,13,14,15,17,19,21,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21];
    uint[] branchCoverage = [0,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,20,21,22,23,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23];
    uint[] blossomCoverage = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24];
    uint[] bgCoverage = [0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,4,4];
    uint constant cW = 64;
    uint constant cH = 96;

    modifier onlyCore {
        require(msg.sender == coreContract);
        _;
    }

    function drawPotted(PottedTypes.MyPotted memory myPotted) private view returns (string memory) {
      bytes[] memory imageData = ppData.getPottedImages();
      return string(abi.encodePacked(
        '<image x="',Strings.toString(myPotted.potted.x),'" y="',Strings.toString(myPotted.potted.y),'" width="',Strings.toString(myPotted.potted.width),'" height="',Strings.toString(myPotted.potted.height),'" image-rendering="pixelated" xlink:href="data:image/png;base64,',Base64.encode(bytes(imageData[myPotted.potted.id])),'"/>'
      ));
    }

    function drawBranch(PottedTypes.MyPotted memory myPotted) private view returns (string memory) {
      bytes[] memory imageData = ppData.getBranchImages();
      return string(abi.encodePacked(
        '<image x="',Strings.toString(myPotted.branch.x),'" y="',Strings.toString(myPotted.branch.y),'" width="',Strings.toString(myPotted.branch.width),'" height="',Strings.toString(myPotted.branch.height),'" image-rendering="pixelated" xlink:href="data:image/png;base64,',Base64.encode(bytes(imageData[myPotted.branch.id])),'"/>'
      ));
    }

    function drawBlossom(PottedTypes.MyPotted memory myPotted, PottedTypes.Gene memory gene) private view returns (string memory) {
      uint blossomCount = (gene.dna + gene.revealNum - 1) % myPotted.branch.pointX.length;
      uint nonce;

      string memory bloosomSvgString = '';
      for (uint i = 0; i < blossomCount; i++) {
        uint randomBlossom = (gene.dna + gene.revealNum + i + 1) % myPotted.blossom.childs.length;

        uint randomPos = uint(keccak256(abi.encodePacked(gene.dna + gene.revealNum, nonce))) % blossomCount;
        nonce++;

        bloosomSvgString = string(abi.encodePacked(
          bloosomSvgString,
          '<image x="',Strings.toString(myPotted.branch.pointX[randomPos] - (myPotted.blossom.width[randomBlossom] / 2)),'" y="',Strings.toString(myPotted.branch.pointY[randomPos] - (myPotted.blossom.height[randomBlossom] / 2)),'" width="',Strings.toString(myPotted.blossom.width[randomBlossom]),'" height="',Strings.toString(myPotted.blossom.height[randomBlossom]),'" image-rendering="pixelated" xlink:href="data:image/png;base64,',Base64.encode(bytes(ppData.getBlossomImages()[myPotted.blossom.childs[randomBlossom]])),'"/>'
        ));
      }

      return bloosomSvgString;
    }

    function drawBg(PottedTypes.MyPotted memory myPotted) private view returns (string memory) {
      bytes[] memory imageData = ppData.getBgImages();
      return string(abi.encodePacked(
        '<image x="0" y="0" width="',Strings.toString(cW),'" height="',Strings.toString(cH),'" image-rendering="pixelated" xlink:href="data:image/png;base64,',Base64.encode(bytes(imageData[myPotted.bg.id])),'"/>'
      ));
    }

    function drawUnreveal() private view returns (string memory) {
      bytes[] memory imageData = ppData.getUnreveal();
      return string(abi.encodePacked(
        '<image x="0" y="0" width="',Strings.toString(cW),'" height="',Strings.toString(cH),'" image-rendering="pixelated" xlink:href="data:image/gif;base64,',Base64.encode(bytes(imageData[0])),'"/>'
      ));      
    }

    function drawUnrevealPP(PottedTypes.Gene memory gene) external onlyCore view returns (string memory)  {
      PottedTypes.MyPotted memory myPotted = getPP(gene);
        return string(abi.encodePacked(
          '<svg width="100%" height="100%" viewBox="0 0 ',Strings.toString(cW),' ',Strings.toString(cH),'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          drawBg(myPotted),
          drawPotted(myPotted),
          drawUnreveal(),
          "</svg>"
        ));
    }

    function drawRevealPP(PottedTypes.Gene memory gene) external onlyCore view returns (string memory) {
      PottedTypes.MyPotted memory myPotted = getPP(gene);
        return string(abi.encodePacked(
          '<svg width="100%" height="100%" viewBox="0 0 ',Strings.toString(cW),' ',Strings.toString(cH),'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          drawBg(myPotted),
          drawPotted(myPotted),
          drawBranch(myPotted),
          drawBlossom(myPotted, gene),
          "</svg>"
        ));
    }

    function drawNoBgPP(PottedTypes.Gene memory gene, uint resulotion) external onlyCore view returns (string memory) {
      PottedTypes.MyPotted memory myPotted = getPP(gene);
        return string(abi.encodePacked(
          '<svg width="',Strings.toString(cW * resulotion),'" height="',Strings.toString(cH * resulotion),'" viewBox="0 0 ',Strings.toString(cW),' ',Strings.toString(cH),'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          drawPotted(myPotted),
          drawBranch(myPotted),
          drawBlossom(myPotted, gene),
          "</svg>"
        ));
    }

    function getPP(PottedTypes.Gene memory gene) public view returns (PottedTypes.MyPotted memory) {
      return PottedTypes.MyPotted(getPotted(gene), getBranch(gene), getBlossom(gene), getBg(gene));
    }

    function getPotted(PottedTypes.Gene memory gene) private view returns (PottedTypes.Potted memory) {
      uint idx = (gene.dna + 1) % pottedCoverage.length;
      return ppData.getAllPotted()[pottedCoverage[idx]];
    }

    function getBranch(PottedTypes.Gene memory gene) private view returns (PottedTypes.Branch memory) {
      uint idx = (gene.dna + gene.revealNum + 2) % branchCoverage.length;
      return ppData.getAllBranch()[branchCoverage[idx]];
    }

    function getBlossom(PottedTypes.Gene memory gene) private view returns (PottedTypes.Blossom memory) {
      PottedTypes.Branch memory branch = getBranch(gene);

      if (branch.unique != 0) {
        return ppData.getAllBlossom()[branch.unique];
      } else {
        uint idx = (gene.dna + gene.revealNum + 3) % blossomCoverage.length;
        return ppData.getAllBlossom()[blossomCoverage[idx]];
      }
    }

    function getBg(PottedTypes.Gene memory gene) private view returns (PottedTypes.Bg memory) {
      uint idx = (gene.dna + 4) % bgCoverage.length;
      return ppData.getAllBg()[bgCoverage[idx]];
    }

    function setDataContract(address _address) external onlyOwner {
      ppData = PPdata(_address);
    }

    function setCoreContract(address _address) external onlyOwner {
      coreContract = _address;
    }
}