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

contract VaultsManager is Ownable {

    enum Status{Pending, Open, Locked, Closed, Exited}
    struct VaultData {
        Status status;
        uint256 price;
        uint256 maxSupply;
        address vaultContract;
        address partnerContract;
        bool publicSale;
        uint256 snapshotId;
        uint256 finalBalance;
    }

    mapping(uint256 => mapping(address => uint256)) public whitelist;

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

    function setWhiteList(uint256 tokenId, address[] memory accounts, uint256[] memory whitelistCounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[tokenId][accounts[i]] = whitelistCounts[i];
        }
    }

    function openPublic(uint256 tokenId) external onlyOwner {
        require(vaults[tokenId].status == Status.Open, "Manager: not enabled");
        vaults[tokenId].publicSale = true;
    }

    function open(uint256 tokenId, uint256 price, uint256 maxSupply, bool publicSale) external onlyOwner {
        require(tokenId > 0, "Manager: tokenId is 0");
        VaultData memory vault = vaults[tokenId];
        require(vault.status == Status.Pending, "Manager: not pending");
        uint256 snapshotId = distributor.snapshot();
        vaults[tokenId] = VaultData({
            status: Status.Open,
            price: price,
            maxSupply: maxSupply,
            vaultContract: address(0),
            partnerContract: address(0),
            publicSale: publicSale,
            snapshotId: snapshotId,
            finalBalance: 0
        });
    }

    function mint(uint256 tokenId, uint256 tokens) external payable {
        VaultData memory vault = vaults[tokenId];
        require(vault.status == Status.Open, "Manager: not enabled");
        require(totalSupply(tokenId) + tokens <= vault.maxSupply, "Manager: exceeds max");
        require(msg.value == vault.price * tokens, "Manager: wrong amount");
        if (!vault.publicSale) {
            uint256 whitelistCount = whitelist[tokenId][msg.sender];
            require(tokens <= whitelistCount, "Manager: exceeds max");
            whitelist[tokenId][msg.sender] = whitelistCount - tokens;
        }
        nft.mint(msg.sender, tokenId, tokens);
    }

    function lock(uint256 tokenId, address vaultContract, address partnerContract) external onlyOwner {
        VaultData storage vault = vaults[tokenId];
        uint256 totalSupply_ = totalSupply(tokenId);
        require(totalSupply_ > 0, "Manager: no tokens");
        require(managementContract != address(0), "Manager: management contract null");
        require(partnerContract != address(0), "Manager: partner contract null");
        require(vault.status == Status.Open, "Manager: contract not open");
        uint256 balance = vault.price * totalSupply_;
        uint256 managementFee = (balance * 15) / 1000;
        uint256 distributableFee = (balance * 10) / 1000;
        uint256 partnerFee = (balance * 25) / 1000;
        uint256 operationAmount = balance - (managementFee + distributableFee + partnerFee);
        vault.status = Status.Locked;
        vault.vaultContract = vaultContract;
        vault.partnerContract = partnerContract;

        distributor.receiveFee{value : distributableFee}(vault.snapshotId);

        IVault(vaultContract).start{value : operationAmount}(tokenId);

        (bool managementPaymentSuccess,) = payable(managementContract).call{value : managementFee}("");
        require(managementPaymentSuccess, "Manager: unsuccessful payment");

        (bool partnerPaymentSuccess,) = payable(partnerContract).call{value : partnerFee}("");
        require(partnerPaymentSuccess, "Manager: unsuccessful payment");
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
        uint256 partnerFee;
        if (msg.value > collected) {
            uint256 profit = msg.value - collected;
            fee = (profit * 5) / 100;
            partnerFee = (profit * 15) / 100;
            distributor.receiveFee{value : fee}(vault.snapshotId);
        }
        vault.finalBalance = msg.value - (fee * 2 + partnerFee);
        vault.status = Status.Closed;
        if (fee > 0) {
            (bool managementPaymentSuccess,) = payable(managementContract).call{value : fee}("");
            require(managementPaymentSuccess, "Manager: unsuccessful payment");
        }
        if (partnerFee > 0) {
            (bool partnerPaymentSuccess,) = payable(vault.partnerContract).call{value : partnerFee}("");
            require(partnerPaymentSuccess, "Manager: unsuccessful payment");
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
