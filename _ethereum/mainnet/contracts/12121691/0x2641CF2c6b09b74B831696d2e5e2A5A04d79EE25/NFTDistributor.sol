// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IPunkBodies.sol";

contract NFTDistributor is Ownable {
    using SafeMath for uint256;

    address public immutable token;
    bytes32 public immutable merkleRoot;

    bool[10000] public minted;
    bool[2000] public claimed;

    uint256 public constant airdrop_period = 24 hours;
    uint256 public constant og_sale_period = 1 hours;
    uint16 public constant reserve_count = 2000; // reserve + airdrop
    uint16 public constant total_count = 10000;

    uint16[10000] pendingIds;

    uint16 public pendingCount = total_count - reserve_count;
    uint16 reserveMintedCount = 0;

    uint256 public startTime;

    event Purchased(address account, uint256 amount, uint256 cost);
    event Claimed(uint256 index, address account, uint256 tokenId);

    constructor(address _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function setStartTime(uint256 t) external onlyOwner {
        require(startTime == 0, "NFTDistributor: Start time already set.");
        startTime = t;
    }

    function mintReserved(address to, uint16[] memory ids) external onlyOwner {
        require(startTime > 0 && startTime + airdrop_period < block.timestamp, "NFTDistributor: Airdrop not finished.");

        for (uint256 i = 0; i < ids.length; i ++) {
            require(ids[i] >= total_count - reserve_count, "NFTDistributor: Not in reserved range.");
            _mint(to, ids[i]); // will revert if already minted
        }
    }

    function claim(uint256 index, address account, bytes32[] calldata merkleProof) external {
        require(isAirdropPeriod(), "NFTDistributor: Not airdrop period.");
        require(!claimed[index], "NFTDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "NFTDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);

        uint16 tokenId = total_count - uint16(index) - 1; // 9999~ airdrop ids

        _mint(account, tokenId);

        emit Claimed(index, account, tokenId);
    }

    // Renamed amount to nonce to avoid confusion
    function ogPurchase(uint256 index, bytes32[] calldata merkleProof, uint256 amount) payable external {
        require(isOgSalePeriod(), "NFTDistributor: Not OG sale period.");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "NFTDistributor: Invalid proof.");
        
        _purchase(amount);
    }

    function purchase(uint256 amount) payable external {
        require(startTime > 0, "NFTDistributor: Not started.");
        require(pendingCount > 0, "NFTDistributor: All minted.");
        require(!isOgSalePeriod(), "NFTDistributor: OG sale not finished.");

        _purchase(amount);
    }

    function isAirdropPeriod() public view returns(bool) {
        return block.timestamp < startTime + airdrop_period && startTime > 0;
    }

    function isOgSalePeriod() public view returns(bool) {
        return block.timestamp < startTime + og_sale_period;
    }

    function getCurrentPrice() public view returns(uint256) {
        if (pendingCount <= 100)
            return 3 ether;
        if (pendingCount <= 1500)
            return 1 ether;
        if (pendingCount <= 3000)
            return 0.7 ether;
        if (pendingCount <= 4800)
            return 0.5 ether;
        if (pendingCount <= 6500)
            return 0.3 ether;
        if (pendingCount <= 8000)
            return 0.1 ether;
        revert("NFTDistributor: Sale ended.");
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function _getPendingAtIndex(uint16 _index) internal view returns(uint16) {
        return pendingIds[_index] + _index;
    }

    function _popPendingAtIndex(uint16 _index) internal returns(uint16) {
        uint16 tokenId = _getPendingAtIndex(_index);
        if (_index != pendingCount) {
            uint16 lastPendingId = _getPendingAtIndex(pendingCount - 1);
            pendingIds[_index] = lastPendingId - _index;   
        }
        pendingCount --;
        return tokenId;
    }

    function _setClaimed(uint256 index) private {
        claimed[index] = true;
    }

    function _purchase(uint256 amount) internal {
        require(amount <= 20, "NFTDistributor: Cannot purchase more than 20 at once.");
        require(msg.value == getCurrentPrice().mul(amount), "NFTDistributor: Price not correct.");

        for (uint256 i = 0; i < amount; i ++) {
            _randomMint(msg.sender);
        }

        emit Purchased(msg.sender, amount, msg.value);
    }

    function _randomMint(address _to) internal {
        uint _idMin;
        if (pendingCount <= 100)
            _idMin = 0;
        else if (pendingCount <= 1500)
            _idMin = 100;
        else if (pendingCount <= 3000)
            _idMin = 1500;
        else if (pendingCount <= 4800)
            _idMin = 3000;
        else if (pendingCount <= 6500)
            _idMin = 4800;
        else if (pendingCount <= 8000)
            _idMin = 6500;

        uint16 index = uint16(_getRandom() % (pendingCount - _idMin) + _idMin);
        uint256 tokenId = _popPendingAtIndex(index);
        IPunkBodies(token).mint(_to, tokenId);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        minted[_tokenId] = true;
        IPunkBodies(token).mint(_to, _tokenId);
    }

    function _getRandom() internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, pendingCount)));
    }
}
