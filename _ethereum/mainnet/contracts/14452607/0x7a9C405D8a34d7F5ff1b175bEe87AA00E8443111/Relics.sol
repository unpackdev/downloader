// SPDX-License-Identifier: MIT

// @title: Paraverse Relics
// @author: Paradox

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./Strings.sol";

contract Relics is ERC1155, Ownable {

    enum Phase {
        NotStarted,
        Prometheus,
        Andromeda,
        Icarus
    }

    Phase private phase;
    string public name;
    string public baseURI;
    address public paragonsAddress;

    mapping(uint256 => bool) public paragonIdsClaimed;
    mapping(uint256 => bool) public paragon7thRelicIdsClaimed;
    uint256[][] public paragonRelics = [[0, 1712], [1713, 3424], [3425, 4925], [4926, 6424], [6425, 7925], [7926, 9423]];
    mapping(uint256 => uint256) public relicPrices;
    mapping(uint256 => uint256) public relicPhases;
    mapping(uint256 => bool) public phaseActive;
    mapping (uint256 => uint256) public relicTotalSupply;

    event PhaseActive(Phase phase, bool isActive);
    event Minted(address minter, uint256[] amount, uint256[] relicIds);

    constructor() ERC1155("https://api.paragonsnft.com/api/token/relics/{id}") {
        name = "The Paraverse: Relics";
        relicPhases[1] = 1;
        relicPhases[2] = 1;
        relicPhases[3] = 2;
        relicPhases[4] = 2;
        relicPhases[5] = 3;
        relicPhases[6] = 3;
    }

    // Mint function
    function claimRelics(uint16[] calldata tokenParagonIds) external payable {
        uint256[] memory relicIds = new uint256[](6);
        relicIds[0] = 1; relicIds[1] = 2; relicIds[2] = 3; relicIds[3] = 4; relicIds[4] = 5; relicIds[5] = 6;
        uint[] memory amounts = _getRelicAmounts(tokenParagonIds);
        //check if the relic phase is active
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if(amounts[i] != 0){
                uint256 currentRelicPhase = relicPhases[relicIds[i]];
                totalPrice += relicPrices[relicIds[i]] * amounts[i];
                require(phaseActive[currentRelicPhase], "The Relic Phase you are trying to mint is not active.");
            }
        }
        require(msg.value >= totalPrice, 'Ether value sent is incorrect.');
        _mintBatchAndSetClaim(msg.sender, relicIds, amounts, tokenParagonIds);
    }

    function claim7thRelic(uint16[] calldata tokenParagonIds) external payable {
        require(tokenParagonIds.length % 4 == 0, "The number of provided paragons must be a multiplier of 4 to create the 7th relic.");
        //ensure sender owns all paragons provided and not claimed yet
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory relicIds = new uint256[](1);
        amounts[0] = tokenParagonIds.length / 4;
        relicIds[0] = 7;
        for (uint256 i = 0; i < tokenParagonIds.length; i++) {
            require(!paragon7thRelicIdsClaimed[tokenParagonIds[i]], "A Given Paragon has already been used to created the 7th Relic.");
            require(isParagonOwner(tokenParagonIds[i], msg.sender), "Address is not the owner of the Given Paragon.");
        }
        for (uint256 i = 1; i < 7; i++) {
            require((balanceOf(msg.sender, i) != 0), "You do not own all 6th relics so you cannot unlock the 7th.");
        }
        uint256 totalPrice = 0;
        totalPrice += relicPrices[7] * amounts[0];
        require(msg.value >= totalPrice, 'Ether value sent is incorrect.');
        _mintBatch(msg.sender, relicIds, amounts, "");
        for (uint256 i = 0; i < tokenParagonIds.length; i++) {
            paragon7thRelicIdsClaimed[tokenParagonIds[i]] = true;
        }
        emit Minted(msg.sender, amounts, relicIds);
    }

    function _mintBatchAndSetClaim(address _address,  uint[] memory relicIds, uint[] memory amounts, uint16[] calldata tokenParagonIds) internal {
        _mintBatch(_address, relicIds, amounts, "");
        for (uint256 i = 0; i < tokenParagonIds.length; i++) {
            paragonIdsClaimed[tokenParagonIds[i]] = true;
        }
        emit Minted(msg.sender, amounts, relicIds);
    }

    function _getRelicAmounts(uint16[] calldata tokenParagonIds) internal view returns(uint[] memory){
        uint256[] memory amounts = new uint256[](6);
        address ownerAddress = owner();
        for (uint256 i = 0; i < tokenParagonIds.length; i++) {
            require(!paragonIdsClaimed[tokenParagonIds[i]], "A Relic has already been claimed in the Paragon Batch");
            if(msg.sender != ownerAddress) require(isParagonOwner(tokenParagonIds[i], msg.sender), "Address is not the owner of the Given Paragon");
            for (uint256 j = 0; j < paragonRelics.length; j++) {
                uint256[] memory currentRelicRange = paragonRelics[j];
                if(tokenParagonIds[i] >= currentRelicRange[0] && tokenParagonIds[i] <= currentRelicRange[1]){
                    amounts[j] += 1;
                }
            }
        }
        return amounts;
    }


    function setTokenUri(string calldata newUri) public onlyOwner {
        baseURI = newUri;
        _setURI(newUri);
    }

    function isRelicClaimedBatch(uint256[] memory paragonTokenIds) public view returns (bool[] memory) {
        bool[] memory relicsClaimed = new bool[](paragonTokenIds.length);
        for (uint256 i = 0; i < paragonTokenIds.length; i++) {
            relicsClaimed[i] = paragonIdsClaimed[paragonTokenIds[i]];
        }
        return relicsClaimed;
    }

    function isParagonOwner(uint256 tokenId, address _address) public view returns (bool) {
        address owner = IERC721(paragonsAddress).ownerOf(tokenId);
        return owner == _address;
    }

    function setParagonAddress(address _address) public onlyOwner {
        paragonsAddress = _address;
    }

    function setPhaseActive(Phase _phase, bool _isActive) public onlyOwner {
        if(_isActive) phase = _phase;
        phaseActive[uint(_phase)] = _isActive;
        emit PhaseActive(phase, _isActive);
    }

    function setRelicPrice(uint256 relicId, uint weiPrice) public onlyOwner {
        relicPrices[relicId] = weiPrice;
    }

    function setContractName(string memory _name) public onlyOwner {
        name = _name;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        string memory idToString = Strings.toString(_id);
        string memory tokenURI = string(abi.encodePacked(baseURI, idToString));
        return tokenURI;
    }
}