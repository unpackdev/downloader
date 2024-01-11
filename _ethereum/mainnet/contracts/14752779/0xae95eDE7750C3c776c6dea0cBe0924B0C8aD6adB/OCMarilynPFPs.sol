// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "./Ownable.sol";
import "./Strings.sol";

import "./base64.sol";
import "./ERC721.sol";

import "./SSTORE2.sol";
import "./DynamicBuffer.sol";

import "./console.sol";

interface DiptychInterface {
    function ownerOf ( uint256 tokenId ) external view returns ( address );
    function getApproved ( uint256 tokenId ) external view returns ( address );
    function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
    function exists ( uint tokenId ) external view returns ( bool );

    function tokenImageWithMetadata(uint tokenId, bool renderSingle, uint rowIdx, uint colIdx) external view returns (bytes memory svg, uint[2] memory squareCounts, bool pfpBrightMode);
    function sideLength() external view returns (uint8);
    function maxSupply() external view returns (uint);
    function getTokenTitleAtIndex(uint index) external view returns (string memory);
}

contract OCMarilynPFPs is ERC721, Ownable {
    using DynamicBuffer for bytes;
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    
    bytes public constant externalLink = "https://capsule21.com/collections/oc-marilyn-pfps";
    
    bytes constant tokenDescription = "OC Marilyn PFPs is a subproject of the OC Marilyn Diptychs. If you can't decide between 1/1 artwork and PFP NFTs, in this project you have them both together.\\n\\nYou can mint an OC Marilyn PFP from a single square of a Diptych you own, where they will be replaced by a placeholder, all the while editing the original artwork. The PFPs can also be put back in the artwork through burning.";
    
    uint public constant costPerToken = 0.005 ether;
    
    bool public contractSealed;
    
    bool public isMintActive;
    
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }
    
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }
    
    constructor() ERC721("OC Marilyn PFPs", "MARILYNPFP") {
    }
    
    DiptychInterface public DiptychContract;
    
    function setDiptychContract(address _contract) external onlyOwner unsealed {
        DiptychContract = DiptychInterface(_contract);
    }
    
    function burn(uint dypIdx, uint rowIdx, uint colIdx) public {
        uint tokenId = coordsToTokenId(dypIdx, rowIdx, colIdx);
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function canMintIndividualMarilyn(address user, uint diptychId) public view returns (bool) {
        address tokenOwner = DiptychContract.ownerOf(diptychId);
        
        return (
            user == tokenOwner ||
            DiptychContract.getApproved(diptychId) == user ||
            DiptychContract.isApprovedForAll(tokenOwner, user)
        );
    }
    
    function mintIndividualMarilyn(address toAddress,
    uint[] memory dypIdxs, uint[] memory rowIdxs, uint[] memory colIdxs) external payable {
        require(isMintActive, "Mint is not active");
        require(msg.value == totalMintCost(dypIdxs.length, msg.sender), "Need exact payment");
        
        for (uint i; i < dypIdxs.length; ++i) {
            uint dypIdx = dypIdxs[i];
            uint rowIdx = rowIdxs[i];
            uint colIdx = colIdxs[i];
            
            uint tokenId = coordsToTokenId(dypIdx, rowIdx, colIdx);
            
            require(canMintIndividualMarilyn(_msgSender(), dypIdx), "You need to own the Diptych to mint the PFP");
            
            _mint(toAddress, tokenId);
        }
    }
    
    function exists(uint dypIdx, uint rowIdx, uint colIdx) public view returns (bool) {
        return _exists(coordsToTokenId(dypIdx, rowIdx, colIdx));
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        return constructTokenURI(id);
    }
    
    function tokenName(uint tokenId) private pure returns (bytes memory) {
        return abi.encodePacked("OC Marilyn PFP #", tokenId.toString());
    }
    
    function getMintedPFPsCountOnDiptych(uint dypIdx) public view returns (uint count) {
        uint tokensPerDyp = DiptychContract.sideLength() ** 2 * 2;
        
        uint startTokenId = dypIdx * tokensPerDyp;
        
        for (uint i = startTokenId; i < startTokenId + tokensPerDyp; i++) {
            if (_exists(i)) {
                ++count;
            }
        }
    }
    
    function getMintedPFPsOnDiptych(uint dypIdx) public view returns (bool[] memory result) {
        uint tokensPerDyp = DiptychContract.sideLength() ** 2 * 2;
        
        result = new bool[](tokensPerDyp);
        
        uint startTokenId = dypIdx * tokensPerDyp;
        
        for (uint i = startTokenId; i < startTokenId + tokensPerDyp; i++) {
            result[i - startTokenId] = _exists(i);
        }
    }
    
    function tokenIdToCoords(uint tokenId) public view returns (uint dypIdx, uint rowIdx, uint colIdx) {
        uint _sl = DiptychContract.sideLength();
        uint tokensPerDyp = _sl ** 2 * 2;
        
        dypIdx = tokenId / tokensPerDyp;
        uint squareIdx = tokenId % tokensPerDyp;
        rowIdx = squareIdx / (_sl * 2);
        colIdx = squareIdx % (_sl * 2);
        
        require(coordsValid(dypIdx, rowIdx, colIdx), "Invalid coords");
    }
    
    function maxSupply() public view returns (uint) {
        uint _sl = DiptychContract.sideLength();
        uint tokensPerDyp = _sl ** 2 * 2;
        
        return tokensPerDyp * DiptychContract.maxSupply();
    }
    
    function coordsToTokenId(uint dypIdx, uint rowIdx, uint colIdx) public view returns (uint tokenId) {
        uint _sl = DiptychContract.sideLength();
        uint tokensPerDyp = _sl ** 2 * 2;
        
        require(coordsValid(dypIdx, rowIdx, colIdx), "Invalid coords");
        
        tokenId = dypIdx * tokensPerDyp + rowIdx * (_sl * 2) + colIdx;
    }
    
    function coordsValid(uint dypIdx, uint rowIdx, uint colIdx) public view returns (bool) {
        uint _sl = DiptychContract.sideLength();
        
        return (
            DiptychContract.exists(dypIdx) &&
            rowIdx < _sl &&
            colIdx < 2 * _sl
        );
    }
    
    function tokenImage(uint tokenId) public view returns (string memory) {
        (uint dypIdx, uint rowIdx, uint colIdx) = tokenIdToCoords(tokenId);
        
        (bytes memory svg,,) = DiptychContract.tokenImageWithMetadata(dypIdx, true, rowIdx, colIdx);
        return string(svg);
    }
    
    function previewImage(uint dypIdx, uint rowIdx, uint colIdx) public view returns (string memory) {
        return tokenImage(coordsToTokenId(dypIdx, rowIdx, colIdx));
    }
    
    function constructTokenURI(uint tokenId) private view returns (string memory) {
        (uint dypIdx, uint rowIdx, uint colIdx) = tokenIdToCoords(tokenId);
        
        (bytes memory svg,,bool pfpBrightMode) = DiptychContract.tokenImageWithMetadata(dypIdx, true, rowIdx, colIdx);
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', tokenName(tokenId), '",'
                                '"description":"', tokenDescription, '",'
                                '"image_data":"data:image/svg+xml;base64,', Base64.encode(svg), '",'
                                '"external_url":"', externalLink, '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "Diptych Title",',
                                            '"value": ', DiptychContract.getTokenTitleAtIndex(dypIdx),
                                        '},'
                                        '{',
                                            '"trait_type": "Diptych Index",',
                                            '"value": "', dypIdx.toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Row Index",',
                                            '"value": "', rowIdx.toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Column Index",',
                                            '"value": "', colIdx.toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "PFP Type",',
                                            '"value": "', (pfpBrightMode ? "Color" : "Black & White"), '"',
                                        '}'
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
    
    function totalMintCost(uint numTokens, address minter) public view returns (uint) {
        if (minter == owner()) {
            return 0;
        }
        
        return numTokens * costPerToken;
    }
    
}