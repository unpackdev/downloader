// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

/**
 * @title
 * @dev
 */
//TODO: REFACTOR TO USE block.timestamp over block.number, more reliable
contract RevestPrivateSale is ERC1155, AccessControlEnumerable, Ownable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant UNIT_PRICE = 1 ether; // Unit price in Wei – 1 ETH
    uint256 public constant TOTAL_UNITS = 1500;
    uint256 public constant PER_CAP = 750;
    uint256 public constant SALE_CAP = 5000 ether;

    address private burner;
    uint256 private floor;

    uint256 private weiRemaining;
    uint256 private balance;

    mapping(address => bool) private whitelist;

    bool private whitelistEnabled;
    bool private enableTransfers;

    address private negativeEntropyAddress;
    uint256 private ticketCap;
    uint256 private ticketAllocation;

    mapping(address => uint256) private ticketSales;
    mapping(uint256 => address) usedTickets;

    /**
     * @dev Primary constructor to create an instance of NegativeEntropy
     * Grants ADMIN and MINTER_ROLE to whoever creates the contract
     *
     */
    constructor(address _negativeEntropyAddress) ERC1155("https://token-cdn-domain/{id}.json") Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        weiRemaining = SALE_CAP;
        burner = address(0);
        enableTransfers = false;
        whitelistEnabled = false;
        whitelist[_msgSender()] = true;
        negativeEntropyAddress = _negativeEntropyAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //Reserve a certain number of NFTs to represent position in private sale
    receive() external payable {
        //Calculate quantity
        require(weiRemaining > 0, "The private sale has been completed");
        require(weiRemaining - msg.value >= 0, "The requested transaction would exceed the private sale cap");
        require(msg.value >= UNIT_PRICE, "Message lacks adequate value for transaction to succeed");
        require(msg.value >= floor, "Must be above floor price");
        require(msg.value % UNIT_PRICE == 0, "Can only purchase RVST FNFTs in whole increments");
        uint256 quantity = msg.value / UNIT_PRICE;
        require(balanceOf(_msgSender(), 0) + quantity < PER_CAP);

        bool canMint = true;

        if (whitelistEnabled) {
            if (!whitelist[_msgSender()]) {
                IERC721Enumerable entropy = IERC721Enumerable(negativeEntropyAddress);
                uint256 nft_balance = entropy.balanceOf(_msgSender());
                if (nft_balance > 0) {
                    require(ticketAllocation > 0, "All RVST allocated to ticket-holders has been claimed!");
                    require(ticketAllocation - msg.value >= 0, "Transaction exceeds RVST allocated to ticket holders");
                    require(ticketSales[_msgSender()] + msg.value <= ticketCap, "Sale would exceed cap!");
                    uint256 tokenID = entropy.tokenOfOwnerByIndex(_msgSender(), 0);
                    require(usedTickets[tokenID] == address(0) || usedTickets[tokenID] == _msgSender(), 'NFTs may only be tied to one address');
                    //Mark ticket used
                    usedTickets[tokenID] = _msgSender();
                    //Add balance to owner's total
                    ticketSales[_msgSender()] = ticketSales[_msgSender()] + msg.value;
                    //Take away balance from ticket allocation
                    ticketAllocation -= msg.value;
                } else {
                    canMint = false;
                }
            }
        }

        require(canMint, "Minting is not enabled for this user at this time");

        //Where we get paid
        balance += (msg.value);

        //Mint NFTs
        _mint(_msgSender(), 0, quantity, "");

        //Finally, adjust internal values
        weiRemaining -= msg.value;
    }

    //Burn function will call a redeem function on our private sale redemption contract
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        require(_msgSender() == burner, "Can only burn via claims contract");
        super._burn(account, id, amount);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(from == address(0) || to == address(0) || enableTransfers, "Transfers of this NFT are currently disabled; please check back later");
    }

    function setBurner(address _burner) public onlyOwner {
        burner = _burner;
    }

    function setFloor(uint256 _floor) public onlyOwner {
        floor = _floor;
    }

    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    function setTransferable(bool enable) external onlyOwner {
        enableTransfers = enable;
    }

    function setWhitelist(bool enable) external onlyOwner {
        whitelistEnabled = enable;
    }

    function setTicket(address negative) external onlyOwner {
        negativeEntropyAddress = negative;
    }

    function setTicketCap(uint256 cap) external onlyOwner {
        require(cap <= weiRemaining,'Cap cannot exceed remaining wei!');
        ticketCap = cap;
    }

    function setTicketAllocation(uint256 allocation) external onlyOwner() {
        require(allocation <= weiRemaining, "Allocation cannot exceed remaining wei!");
        ticketAllocation = allocation;
    }

    function addToWhitelist(address addr) public onlyOwner {
        whitelist[addr] = true;
    }

    function batchAddToWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    ///Amount is in wei
    function adjustCap(uint256 amount, bool increase) public onlyOwner {
        if(increase) {
            weiRemaining += amount;
        } else {
            require(weiRemaining - amount >= 0, 'Negative!');
            weiRemaining -= amount;
        }
    }

    function withdraw() public onlyOwner {
        uint256 amount = balance;
        balance = 0;
        payable(_msgSender()).transfer(amount);
    }

    function getBurner() public view returns (address) {
        return burner;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function getRemainingEth() public view returns (uint256) {
        return weiRemaining;
    }

    function getFloor() public view returns (uint256) {
        return floor;
    }

    function getWhitelistEnabled() public view returns (bool) {
        return whitelistEnabled;
    }

    function getTransferable() public view returns (bool) {
        return enableTransfers;
    }

    function getTicket() public view returns (address) {
        return negativeEntropyAddress;
    }

    function getTicketCap() public view returns (uint256) {
        return ticketCap;
    }

    function getTicketAllocation() public view returns (uint256) {
        return ticketAllocation;
    }

    function getNegativeEntropyCount() public view returns (uint256) {
        IERC721Enumerable entropy = IERC721Enumerable(negativeEntropyAddress);
        return entropy.totalSupply();
    }
}
