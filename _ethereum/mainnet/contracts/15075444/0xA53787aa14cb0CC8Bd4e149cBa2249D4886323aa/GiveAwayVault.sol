// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721Holder.sol";
import "./IERC1271.sol";
import "./IERC721.sol";
import "./IERC20.sol";

interface IWrappedEther {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface INft {
    function mint(address sender, uint256 tokenId, uint256 tokens) external;

    function burn(address sender, uint256 tokenId, uint256 tokens) external;

    function totalSupply(uint256 tokenId) view external returns (uint256);

    function balanceOf(address investor, uint256 tokenId) view external returns (uint256);
}

interface IPoolDistributor {
    function snapshot() external returns (uint256);

    function receiveFee(uint256 snapshotId) external payable;
}

contract GiveAwayVault is Ownable, ERC721Holder, IERC1271 {
    using ECDSA for bytes32;

    bool public closed;
    uint256 public snapshotId;
    uint256 public tokenId;
    INft immutable public poolNft;
    IPoolDistributor immutable public poolDistributor;

    address immutable public tokenContract;
    IWrappedEther immutable public wrappedEther;
    address public openSeaExchange;
    address public openSeaConduit;

    constructor(
        uint256 tokenId_,
        address poolNft_,
        address poolDistributor_,
        address tokenContract_,
        address wrappedEther_,
        address openSeaExchange_,
        address openSeaConduit_
    ) {
        require(tokenId_ > 0, "GiveAwayVault: tokenId is 0");
        require(poolNft_ != address(0), "GiveAwayVault: NFT address should be provided");
        require(poolDistributor_ != address(0), "GiveAwayVault: Distributor address should be provided");
        tokenId = tokenId_;
        poolNft = INft(poolNft_);
        poolDistributor = IPoolDistributor(poolDistributor_);
        tokenContract = tokenContract_;
        wrappedEther = IWrappedEther(wrappedEther_);
        openSeaExchange = openSeaExchange_;
        openSeaConduit = openSeaConduit_;
    }


    function totalSupply() view public returns (uint256) {
        return poolNft.totalSupply(tokenId);
    }

    function balanceOf(address account_) view public returns (uint256){
        return poolNft.balanceOf(account_, tokenId);
    }

    function airdrop(uint256 tokens_, address account_) external onlyOwner {
        require(!closed, "GiveAwayVault: not enabled");
        if (snapshotId == 0) {
            snapshotId = poolDistributor.snapshot();
        }
        poolNft.mint(account_, tokenId, tokens_);
    }

    function close(address managementContract_, address partnerContract_) external onlyOwner {
        require(managementContract_ != address(0), "GiveAwayVault: management contract not set");
        require(partnerContract_ != address(0), "GiveAwayVault: partner contract not set");
        require(!closed, "GiveAwayVault: not locked");
        require(IERC721(tokenContract).balanceOf(address(this)) == 0, "GiveAwayVault: not all tokens sold");
        unWrap();

        uint256 balance = address(this).balance;
        require(balance > 0, "GiveAwayVault: no ether");
        closed = true;

        uint256 managementFee = (balance * 5) / 100;
        uint256 distributableFee = (balance * 5) / 100;
        uint256 partnerFee = (balance * 15) / 100;

        (bool managementContractSuccess,) = payable(managementContract_).call{value : managementFee}("");
        require(managementContractSuccess, "GiveAwayVault: unsuccessful payment");

        poolDistributor.receiveFee{value : distributableFee}(snapshotId);

        (bool partnerContractSuccess,) = payable(partnerContract_).call{value : partnerFee}("");
        require(partnerContractSuccess, "GiveAwayVault: unsuccessful payment");
    }

    function claimable(address account_) public view returns (uint256) {
        return (address(this).balance * balanceOf(account_)) / totalSupply();
    }

    function claim() external {
        require(closed, "GiveAwayVault: claim not available");
        uint256 nftBalance = balanceOf(msg.sender);
        require(nftBalance > 0, "GiveAwayVault: nothing to claim");
        uint256 amount = (address(this).balance * nftBalance) / totalSupply();

        poolNft.burn(msg.sender, tokenId, nftBalance);

        (bool success,) = payable(msg.sender).call{value : amount}("");
        require(success, "GiveAwayVault: unsuccessful payment");
    }

    function updateOpenSeaData(address openSeaExchange_, address openSeaConduit_) external onlyOwner {
        require(openSeaExchange_ != address(0), "GiveAwayVault: OpenSea exchange not set");
        require(openSeaConduit_ != address(0), "GiveAwayVault: OpenSea conduit not set");
        openSeaExchange = openSeaExchange_;
        openSeaConduit = openSeaConduit_;
    }

    function prepareOpenSea() external onlyOwner {
        IERC721(tokenContract).setApprovalForAll(openSeaConduit, true);
    }

    function exchangeOpenSea(bytes calldata _calldata) external onlyOwner {
        (bool _success,) = openSeaExchange.call(_calldata);
        require(_success, "GiveAwayVault: error sending data to exchange");
    }

    receive() external payable {
    }

    function unWrap() public onlyOwner {
        uint256 balance = wrappedEther.balanceOf(address(this));
        if (balance > 0) {
            wrappedEther.withdraw(balance);
        }
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external override view returns (bytes4) {
        address signer = _hash.recover(_signature);
        if (signer == owner()) {
            return 0x1626ba7e;
        }
        return 0x00000000;
    }
}
