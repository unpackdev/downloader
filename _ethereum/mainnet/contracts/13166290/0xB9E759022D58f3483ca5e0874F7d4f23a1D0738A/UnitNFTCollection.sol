// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

/*
    The Unit Collection is the final step of the absolute unit game and was a revolutionary new way to launch a
    PFP NFT collection on the Ethereum blockchain.
*/
contract UnitNFTCollection is ERC721Enumerable, Ownable, ReentrancyGuard {
    string private _baseTokenURI;
    mapping(address => uint256) private unitEligibleAddresses;
    address[] private absUnitEligibleAddresses;
    address private theAbsoluteUnit;
    uint256 private endClaimingDateAndTime;
    bool private initialized;

    modifier onlyClaimingPeriod() {
        require(endClaimingDateAndTime > block.timestamp, "Claiming period is over");
        _;
    }

    constructor() ERC721("Unit Collection", "Unit") {}

    function initialize(
        string memory baseURI,
        address _owner,
        address[] memory _unitEligibleAddresses,
        uint256[] memory _unitCounts,
        address[] memory _absUnitEligibleAddresses,
        address _theAbsoluteUnit,
        uint256 _endClaimingDateAndTime
    ) external nonReentrant onlyOwner {
        require(initialized == false, "wut??");
        initialized = true;
        setBaseURI(baseURI);
        theAbsoluteUnit = _theAbsoluteUnit;
        endClaimingDateAndTime = _endClaimingDateAndTime;
        absUnitEligibleAddresses = _absUnitEligibleAddresses;
        for (uint256 i = 0; i < _unitEligibleAddresses.length; i++) {
            address eligibleAddress = _unitEligibleAddresses[i];
            uint256 count = _unitCounts[i];
            unitEligibleAddresses[eligibleAddress] = count;
        }
        transferOwnership(_owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setEndClaimingPeriod(uint256 _endClaimingDateAndTime) external onlyOwner {
        endClaimingDateAndTime = _endClaimingDateAndTime;
    }

    function claimUnits(uint256 count) external nonReentrant onlyClaimingPeriod {
        require(unitEligibleAddresses[msg.sender] > 0, "You are not eligible to claim");
        uint256 currentSupply = totalSupply();

        for (uint256 i = 0; i < count && unitEligibleAddresses[msg.sender] > 0; i++) {
            unitEligibleAddresses[msg.sender] -= 1;
            _mint(msg.sender, currentSupply + i);
        }
    }

    function claimTheAbsUnit() external nonReentrant onlyClaimingPeriod {
        require(theAbsoluteUnit == msg.sender, "You are not eligible to claim");
        theAbsoluteUnit = address(0);
        _mint(msg.sender, 1001);
    }

    function claimPastAbsUnitHolders() external nonReentrant onlyClaimingPeriod {
        uint256 index;
        for (uint256 i = 0; i < absUnitEligibleAddresses.length; i++) {
            if (absUnitEligibleAddresses[i] == msg.sender) {
                absUnitEligibleAddresses[i] = address(0);
                index = i + 1;
                break;
            }
        }
        require(index > 0, "You are not eligible to claim");
        _mint(msg.sender, 1001 + index);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (endClaimingDateAndTime > block.timestamp) {
            return "https://absunit.co/assets/nft-placeholder.json";
        } else {
            string memory uri = super.tokenURI(tokenId);
            return string(abi.encodePacked(uri, ".json"));
        }
    }
}
