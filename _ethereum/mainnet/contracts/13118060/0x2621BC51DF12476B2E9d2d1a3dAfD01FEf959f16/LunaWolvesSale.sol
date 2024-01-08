// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ILunaWolves.sol";

interface PaymentSplitter {
    function pay(uint id) external payable;
}

interface WolfGang {
    function tokensOfOwner(address _owner) external view returns(uint[] memory);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract LunaWolvesSale is Ownable {
    using SafeMath for uint256;
    ILunaWolves public lunaWolves;

    uint public mintPhase = 0;
    uint public constant MAX_SUPPLY = 3500;
    uint public constant PHASE_1_MAX_SUPPLY = 1000;
    uint public constant PHASE_2_MAX_SUPPLY = 2000;

    mapping(uint => bool) public wolfHasMintedLuna;

    WolfGang _wolfGangContract;

    modifier mintAvailable(uint quantity) {
        uint wolvesBalance = _wolfGangContract.balanceOf(msg.sender);
        require(mintPhase > 0, "mint is not available yet");
        
        if (mintPhase == 1) {
            require(totalSupply().add(quantity) <= PHASE_1_MAX_SUPPLY);
            require(_wolfGangContract.balanceOf(msg.sender) >= 15, "you need at least 15 wolves to mint");
        } else if (mintPhase == 2) {
            require(totalSupply().add(quantity) <= PHASE_2_MAX_SUPPLY);
            require(_wolfGangContract.balanceOf(msg.sender) >= 5, "you need at least 5 wolves to mint");
        }

        _;
    }

    constructor(address _lunaWolves) {
        lunaWolves = ILunaWolves(_lunaWolves);
        _wolfGangContract = WolfGang(0x88c2b948749b13aBC1e0AE4B50ebeb2131D283C1);
    }

    function mintLunas(uint quantity) public payable mintAvailable(quantity) {
        uint[] memory availableWolves = availableWolvesOfOwner(msg.sender);
        uint numberOfLunas;

        require(availableWolves.length >= quantity, "not enouth available wolves to mint lunas");

        if (totalSupply().add(availableWolves.length) > MAX_SUPPLY) {
            numberOfLunas = MAX_SUPPLY.sub(totalSupply());
        } else {
            numberOfLunas = availableWolves.length;
        }

        numberOfLunas = numberOfLunas > quantity ? quantity : numberOfLunas;

        for (uint i = 0; i < numberOfLunas; i++) {
            wolfHasMintedLuna[availableWolves[i]] = true;
            lunaWolves.mint(msg.sender);
        }
    }

    function mintLuna(uint tokenId) public payable mintAvailable(1) {
        require(_wolfGangContract.ownerOf(tokenId) == msg.sender, "sender is not the owner of this wolf");
        require(wolfHasMintedLuna[tokenId] == false, "this wolf already minted a luna");

        wolfHasMintedLuna[tokenId] = true;
        lunaWolves.mint(msg.sender);
    }

    function availableWolvesOfOwner(address owner) public view returns (uint[] memory) {
        uint[] memory wolvesOfOwner = _wolfGangContract.tokensOfOwner(owner);

        uint unclaimedLunas = 0;
        for(uint index = 0; index < wolvesOfOwner.length; index++) {
            if (wolfHasMintedLuna[wolvesOfOwner[index]] == false) {
                unclaimedLunas++;
            }
        }

        uint[] memory availableWolves = new uint[](unclaimedLunas);
        uint availableWolvesIndex = 0;
        for(uint index = 0; index < unclaimedLunas; index++) {
            if (wolfHasMintedLuna[wolvesOfOwner[index]] == false) {
                availableWolves[availableWolvesIndex] = wolvesOfOwner[index];
                availableWolvesIndex++;
            }
        }

        return availableWolves;
    }

    function setMintPhase(uint _phase) public onlyOwner {
        mintPhase = _phase;
    }

    function mintLunasToAddresses(address[] calldata receivers) external onlyOwner {
        for (uint index = 0; index < receivers.length; index++) {
            lunaWolves.mint(receivers[index]);
        }
    }

    function mintLunaTo(address receiver) external onlyOwner {
        lunaWolves.mint(receiver);
    }

    function totalSupply() public view returns (uint) {
        return lunaWolves.totalSupply();
    }
}
