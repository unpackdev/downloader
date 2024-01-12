// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Holder.sol";
import "./ECDSA.sol";
import "./IERC1271.sol";

interface IWrappedEther {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract PersonalBotVault is ERC721Holder, IERC1271 {
    using ECDSA for bytes32;

    IWrappedEther immutable public wrappedEther;
    address public openSeaConduit;
    address immutable public owner;
    address public signer;

    constructor(
        address owner_,
        address signer_,
        address wrappedEtherAddress_,
        address openSeaConduit_
    ) {
        owner = owner_;
        signer = signer_;
        wrappedEther = IWrappedEther(wrappedEtherAddress_);
        openSeaConduit = openSeaConduit_;
        require(IWrappedEther(wrappedEtherAddress_).approve(openSeaConduit_, type(uint).max), "Pool: error approving WETH");
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function updateOpenSeaData(address openSeaConduit_) external onlyOwner {
        openSeaConduit = openSeaConduit_;
        require(wrappedEther.approve(openSeaConduit_, type(uint).max), "Pool: error approving WETH");
    }

    function isValidSignature(bytes32 hash_, bytes calldata signature_) external override view returns (bytes4) {
        address signer_ = hash_.recover(signature_);
        if (signer_ == signer) {
            return 0x1626ba7e;
        }
        return 0x00000000;
    }
}

contract PersonalBotVaultFactory {
    mapping(address => address) public vaults;
    address immutable wrappedEtherAddress;

    constructor(address wrappedEtherAddress_) {
        wrappedEtherAddress = wrappedEtherAddress_;
    }

    function create(
        address signer_,
        address openSeaConduit_
    ) public {
        require(vaults[msg.sender] == address(0));
        PersonalBotVault vault = new PersonalBotVault(
            msg.sender,
            signer_,
            wrappedEtherAddress,
            openSeaConduit_
        );
        vaults[msg.sender] = address(vault);
    }
}
