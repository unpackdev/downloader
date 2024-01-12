// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";


interface IVault {
    function start(uint256 tokenId) external payable;

    function distributeRewards(address account, uint256 balance, uint256 totalSupply) external;
}

interface INft {
    function mint(address sender, uint256 tokenId, uint256 tokens) external;

    function burn(address sender, uint256 tokenId, uint256 tokens) external;

    function totalSupply(uint256 tokenId) view external returns (uint256);

    function balanceOf(address account, uint256 tokenId) view external returns (uint256);
}

interface IDistributor {
    function snapshot() external returns (uint256);

    function receiveFee(uint256 snapshotId) external payable;
}

contract VaultsManagerV2 is Ownable {

    enum Status{Pending, Open, Locked, Closed, Exited}
    struct VaultData {
        Status status;
        uint256 price;
        uint256 maxSupply;
        address vaultContract;
        uint256 snapshotId;
        uint256 finalBalance;
    }

    mapping(uint256 => VaultData) public vaults;
    address public managementContract;
    INft immutable public nft;
    IDistributor immutable public distributor;

    constructor(address nft_, address distributor_) {
        nft = INft(nft_);
        distributor = IDistributor(distributor_);
    }

    function setManagementContract(address managementContract_) external onlyOwner {
        managementContract = managementContract_;
    }

    function totalSupply(uint256 tokenId) view public returns (uint256) {
        return nft.totalSupply(tokenId);
    }

    function balanceOf(address account, uint256 tokenId) view public returns (uint256){
        return nft.balanceOf(account, tokenId);
    }

    function open(uint256 tokenId, uint256 price, uint256 maxSupply) external onlyOwner {
        require(tokenId > 0, "Manager: tokenId is 0");
        VaultData memory vault = vaults[tokenId];
        require(vault.status == Status.Pending, "Manager: not pending");
        uint256 snapshotId = distributor.snapshot();
        vaults[tokenId] = VaultData({
            status: Status.Open,
            price: price,
            maxSupply: maxSupply,
            vaultContract: address(0),
            snapshotId: snapshotId,
            finalBalance: 0
        });
    }

    function mint(uint256 tokenId, uint256 tokens) external payable {
        VaultData memory vault = vaults[tokenId];
        require(vault.status == Status.Open, "Manager: not enabled");
        require(totalSupply(tokenId) + tokens <= vault.maxSupply, "Manager: exceeds max");
        require(msg.value == vault.price * tokens, "Manager: wrong amount");
        nft.mint(msg.sender, tokenId, tokens);
    }

    function lock(uint256 tokenId, address vaultContract) external onlyOwner {
        VaultData storage vault = vaults[tokenId];
        uint256 totalSupply_ = totalSupply(tokenId);
        require(totalSupply_ > 0, "Manager: no tokens");
        require(managementContract != address(0), "Manager: management contract null");
        require(vault.status == Status.Open, "Manager: contract not open");
        uint256 balance = vault.price * totalSupply_;
        uint256 managementFee = (balance * 3) / 100;
        uint256 distributableFee = (balance * 2) / 100;
        uint256 operationAmount = balance - (managementFee + distributableFee);
        vault.status = Status.Locked;
        vault.vaultContract = vaultContract;

        distributor.receiveFee{value : distributableFee}(vault.snapshotId);

        IVault(vaultContract).start{value : operationAmount}(tokenId);

        (bool managementPaymentSuccess,) = payable(managementContract).call{value : managementFee}("");
        require(managementPaymentSuccess, "Manager: unsuccessful payment");
    }

    function allowExit(uint256 tokenId) external onlyOwner {
        VaultData storage vault = vaults[tokenId];
        require(vault.status == Status.Open, "Manager: bad status");
        vault.status = Status.Exited;
    }

    function exit(uint256 tokenId) external {
        VaultData memory vault = vaults[tokenId];
        require(vault.status == Status.Exited, "Manager: exit not possible");
        uint256 balance = balanceOf(msg.sender, tokenId);
        require(balance > 0, "Manager: not a holder");
        nft.burn(msg.sender, tokenId, balance);
        (bool success,) = payable(msg.sender).call{value : balance * vault.price}("");
        require(success, "Manager: unsuccessful payment");
    }

    function close(uint256 tokenId) external payable {
        VaultData storage vault = vaults[tokenId];
        require(vault.status == Status.Locked, "Manager: not locked");
        require(msg.sender == vault.vaultContract, "Manager: only vault");
        uint256 collected = totalSupply(tokenId) * vault.price;
        uint256 fee;
        if (msg.value > collected) {
            uint256 profit = msg.value - collected;
            fee = (profit * 10) / 100;
            distributor.receiveFee{value : fee}(vault.snapshotId);
        }
        vault.finalBalance = msg.value - (fee * 2);
        vault.status = Status.Closed;
        if (fee > 0) {
            (bool managementPaymentSuccess,) = payable(managementContract).call{value : fee}("");
            require(managementPaymentSuccess, "Manager: unsuccessful payment");
        }
    }

    function claimable(address account, uint256 tokenId) public view returns (uint256) {
        uint256 balance = balanceOf(account, tokenId);
        uint256 finalBalance = vaults[tokenId].finalBalance;
        uint256 totalSupply_ = totalSupply(tokenId);
        return (finalBalance * balance) / totalSupply_;
    }

    function claim(uint256 tokenId) external {
        VaultData storage vault = vaults[tokenId];
        require(vault.status == Status.Closed, "Manager: claim not available");
        uint256 balance = balanceOf(msg.sender, tokenId);
        require(balance > 0, "Manager: nothing to claim");
        uint256 totalSupply_ = totalSupply(tokenId);
        uint256 finalBalance = vault.finalBalance;
        uint256 amount = (finalBalance * balance) / totalSupply_;

        IVault(vault.vaultContract).distributeRewards(msg.sender, balance, totalSupply_);

        vault.finalBalance = finalBalance - amount;
        nft.burn(msg.sender, tokenId, balance);

        (bool success,) = payable(msg.sender).call{value : amount}("");
        require(success, "Manager: unsuccessful payment");
    }
}
