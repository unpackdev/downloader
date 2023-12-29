// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

contract Club7 is ERC1155, Ownable, Pausable {
    using Strings for uint256;

    string public constant name = "Club 7";
    string public constant symbol = "Club 7";

    string public contractURI;
    function changeContractURI(string calldata contractURI_) external onlyOwner {
        contractURI = contractURI_;
    }

    bool public publicLive;
    bool public wlLive;

    function toggleSale(uint256 index, bool value_) external onlyOwner {
        if(index == 0) publicLive = value_;
        if(index == 1) wlLive = value_;
    } 
    
    bool public unlocked;
    function setUnlocked(bool unlocked_) external onlyOwner {
        unlocked = unlocked_;
    }

    string baseURI = "https://ipfs.io/ipfs/QmX6aZZHFtLM6qh4ikeRmX5EudoHEugZDhPUqBrc6ww2cA/";
    function setURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    uint256 public totalSupply;
    /**
        @dev this is for emergency in case something goes wrong
     */
    function overrideTotalSupply(uint256 totalSupply_) external onlyOwner {
        totalSupply = totalSupply_;
    }

    /**
        @dev this is for emergency in case something goes wrong
     */
    function burn(address from, uint256 id, uint256 amount) external onlyOwner {
        totalSupply -= amount;
        _burn(from, id, amount);        
    }

    uint256 public cost = 2 ether;
    function changeCost(uint256 cost_) external onlyOwner {
        cost = cost_;
    }

    uint256 public limit = 1;
    function changeLimit(uint256 limit_) external onlyOwner {
        limit = limit_;
    }
 
    uint256 public maxSupply = 1000;
    function changeMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    mapping(uint256 => bytes32) private _root;

    function root(uint256 index) public view returns (bytes32) {
        return _root[index];
    }

    function changeRoot(uint256 index_, bytes32 root_) external onlyOwner {
        _root[index_] = root_;
    }

    mapping(address => uint256) _minted;
    
    function minted(address to) public view returns (uint256) {
        return _minted[to];
    }

    mapping(uint256 => mapping(address => bool)) _whitelisted;

    function whitelisted(uint256 index_, address to_) public view returns (bool) {
        return _whitelisted[index_][to_];
    }
    
    function addToWhitelist(uint256 index_, address to_, bool value_) external onlyOwner {
        _whitelisted[index_][to_] = value_;
    }
    
    mapping(address => bool) _claimed;

    function claimed(address to) public view returns (bool) {
        return _claimed[to];
    }

    constructor() ERC1155("") {
        // claim
        _root[2] = 0x55c39569fea9fd32d18a9b8e8ca8a757604febb6b66ed1cb715e5512ee0a1910;
        // whitelist
        _root[1] = 0x5b18ee0e30b6304d2f9e1075f9cb4b04a56063db79418467e3d960fab60ee2d0;
    }

    function verified(uint256 index, address to, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, _root[index], keccak256(abi.encodePacked(to))) || _whitelisted[index][to];
    }

    function adminMint(address[] calldata recipients_, uint256[] calldata amounts_) external onlyOwner {
        for(uint256 i; i < recipients_.length; i++) {
            require(totalSupply + amounts_[i] <= maxSupply, "Exceeds Supply");
            totalSupply += amounts_[i];
            _mint(recipients_[i], 1, amounts_[i], "");
        }
    }

    function claim(bytes32[] calldata proof) external payable whenNotPaused {
        require(wlLive, "Not live");
        require(!claimed(msg.sender), "Claimed");
        require(verified(2, msg.sender, proof), "Not in Claim");
        _claimed[msg.sender] = true;
        _callMint(msg.sender);
        refundIfOver(0);
    }

    function wlMint(bytes32[] calldata proof) external payable whenNotPaused {
        require(wlLive, "Not live");
        require(_minted[msg.sender] + 1 <= limit, "Exceeds balance");
        require(verified(1, msg.sender, proof), "Not in Whitelist");
        unchecked { ++_minted[msg.sender]; }
        _callMint(msg.sender);
        refundIfOver(cost);
    }

    function mint() external payable whenNotPaused {
        require(publicLive, "Not live");
        _callMint(msg.sender);
        refundIfOver(cost);
    }

    function refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Not enough ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _callMint(address to_) internal {
        require(tx.origin == msg.sender, "EOA");
        require(totalSupply + 1 <= maxSupply, "Exceeds Supply");
        unchecked { ++totalSupply; }
        _mint(to_, 1, 1, "");       
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        if(!unlocked) return false;
        return super.isApprovedForAll(account, operator);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(unlocked, "locked");
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        if(from != address(0x0) && to != address(0x0)) {
            require(unlocked, "locked");
        }        
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 id_) public view virtual override returns (string memory) {
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        id_.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setPaused(bool paused_) external onlyOwner {
        if(paused_) {
            _pause();
        } else {
            _unpause();
        }
    }

    function withdraw(uint256 amountInWei, bool withdrawAll) external onlyOwner {
        if(withdrawAll) {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            payable(msg.sender).transfer(amountInWei);
        }        
    }
}