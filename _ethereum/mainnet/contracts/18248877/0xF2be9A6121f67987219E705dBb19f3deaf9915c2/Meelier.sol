/*
 * Meelier MIGU
 *
 *
 * Website: https://www.meelier.io/
 * Twitter: https://twitter.com/MiguMeelier
 * Discord: https://discord.gg/meelier
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./IERC4906.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";

contract Meelier is ERC721Enumerable, Ownable, IERC4906, AccessControl, ERC721Burnable, ReentrancyGuard{
    using SafeMath for uint256;
    uint256 private _total_issue;
    string public _baseTokenURI;
    bytes32 public _merkleRoot;
    mapping(uint=>mapping(address=>bool)) public _whitelist;
    mapping(uint=>uint) public _whitelistCount;
    struct issueBatchData{
        uint256 startIndex;
        uint256 count;
        uint256 price;
        uint256 whitePrice;
        bool mintWhite;
    }
    mapping(uint=>issueBatchData) public _issueBatch;
    uint256 public _issueBatchCount;
    bool public _issueLock;
    mapping(uint=>bool) public _startMint;
    uint256 private _whitelistMintLimit;
    uint256 private _threshold;
    struct withdrawProposal {
        address proposer;
        address[] supporters;
        address beneficiary;
        bool execute;
    }
    mapping(uint=>withdrawProposal) public _withdrawProposalList;
    uint256 public _withdrawProposalCount;
    bool public _withdrawNeedProposal;
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    uint256 public _withdrawProposerCount;
    uint256 public _mintStartIndex;
    uint256 public _mintStartTokenId;

    event makeWithdrawProposal(address proposer, address beneficiary, uint id);
    event executeWithdrawProposal(uint id);

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_) ERC721(name_, symbol_) {
        _baseTokenURI = baseTokenURI_;
        _issueBatch[0] = issueBatchData({
            startIndex: 1,
            count: 1000,
            price: 0.05 ether,
            whitePrice:0.03 ether,
            mintWhite: true
        });
        _issueBatchCount = 1;
        _total_issue = 1000;
        _whitelistMintLimit = 1;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(WITHDRAW_ROLE, _msgSender());
        _withdrawProposerCount = 1;
        //_setRoleAdmin(WITHDRAW_ROLE, DEFAULT_ADMIN_ROLE);
        _threshold = 2; // 2/3
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable,AccessControl,IERC165,ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
    
    function addIssueBatch(uint256 startIndex_, uint256 count_,uint256 price_, uint256 whitePrice_, bool mintWhite_) external onlyOwner() {
        require(!_issueLock, "Add issue forbid");
        _issueBatch[_issueBatchCount] = issueBatchData(startIndex_, count_, price_, whitePrice_, mintWhite_);
        _issueBatchCount = _issueBatchCount.add(1);
    }

    function updateIssueBatch(uint256 index_, uint256 startIndex_, uint256 count_,uint256 price_, uint256 whitePrice_,bool mintWhite_) external onlyOwner() {
        require(!_issueLock, "Update issue forbid");
        require(index_ < _issueBatchCount, "Index out of bound");
        _issueBatch[index_].startIndex =  startIndex_;
        _issueBatch[index_].count =  count_;
        _issueBatch[index_].price =  price_;
        _issueBatch[index_].whitePrice =  whitePrice_;
        _issueBatch[index_].mintWhite =  mintWhite_;
    }

    function removeIssueBatch() external onlyOwner() {
        require(!_issueLock, "Remove issue forbid");
        require(_issueBatchCount > 0, "Batch empty");
        delete _issueBatch[_issueBatchCount.sub(1)];
        _issueBatchCount = _issueBatchCount.sub(1);
    }

    //false:public sale,do not need whitelist.
    function publicSale(uint256 index_) external onlyOwner() {
        require(index_ < _issueBatchCount, "Index out of batch bound");
        _issueBatch[index_].mintWhite =  false;
    }

    function lockIssue() external onlyOwner() {
        _issueLock = true;
    }

    function setMintStartTokenId(uint256 mintStartTokenId_) external onlyOwner() {
        _mintStartTokenId = mintStartTokenId_;
    }

    function currentTokenId() public view returns (uint256) {
        return _mintStartIndex.add(1).add(_mintStartTokenId);
    }

    function setTotalIssue(uint256 total_issue_) external onlyOwner() {
        require(!_issueLock, "Update issue forbid");
        _total_issue = total_issue_;
    }

    function setThreshold(uint256 threshold_) external onlyOwner() {
        _threshold = threshold_;
        if(_withdrawProposalCount > 0) {
            tryExecuteWithdrawProposal(_withdrawProposalCount.sub(1));
        }
    }

    function setWhitelistMintLimit(uint256 whitelistMintLimit_) external onlyOwner() {
        _whitelistMintLimit = whitelistMintLimit_;
    }

    function whitelistMintLimit() public view returns (uint256) {
        return _whitelistMintLimit;
    }

    function totalIssue() public view returns (uint256) {
        return _total_issue;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner() {
        _merkleRoot = merkleRoot_;
    }
    
    function addWhitelist(uint256 index_,address lucky_) external onlyOwner() {
        require(index_ < _issueBatchCount, "Index out of batch bound");
        if(!_whitelist[index_][lucky_]) {
            _whitelist[index_][lucky_] = true;
            _whitelistCount[index_] = _whitelistCount[index_].add(1);
        }
    }

    function addWhitelistBatch(uint256 index_, address[] memory lucky_) external onlyOwner() {
        require(index_ < _issueBatchCount, "Index out of batch bound");
        uint256 count = lucky_.length;
        for (uint256 i = 0; i < count; i++) {
            if(!_whitelist[index_][lucky_[i]]) {
                _whitelist[index_][lucky_[i]] = true;
                _whitelistCount[index_] = _whitelistCount[index_].add(1);
            }
        }
    }

    function removeWhitelist(uint256 index_, address lucky_) external onlyOwner() {
        require(index_ < _issueBatchCount, "Index out of batch bound");
        if(_whitelist[index_][lucky_]) {
            _whitelist[index_][lucky_] = false;
            _whitelistCount[index_] = _whitelistCount[index_].sub(1);
        }
    }

    function removeWhitelistBatch(uint256 index_, address[] memory lucky_) external onlyOwner() {
        require(index_ < _issueBatchCount, "Index out of batch bound");
        uint256 count = lucky_.length;
        for (uint256 i = 0; i < count; i++) {
            if(_whitelist[index_][lucky_[i]]) {
                _whitelist[index_][lucky_[i]] = false;
                _whitelistCount[index_] = _whitelistCount[index_].sub(1);
            }
        }
    }

    function whitelistClaim(uint256 index_, bytes32[] calldata merkleProof_) public{
        require(!_whitelist[index_][_msgSender()], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(merkleProof_, _merkleRoot, leaf), "Invalid proof.");
        _whitelist[index_][_msgSender()] = true;
        _whitelistCount[index_] = _whitelistCount[index_].add(1);
    }

    function startMint(uint batchIndex_) external onlyOwner() {
        require(batchIndex_ < _issueBatchCount, "Index out of bound");
        _startMint[batchIndex_] = true;
    }

    function stopMint(uint batchIndex_) external onlyOwner() {
        require(batchIndex_ < _issueBatchCount, "Index out of bound");
        _startMint[batchIndex_] = false;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseTokenURI = baseURI_;
        emit BatchMetadataUpdate(1, _total_issue.sub(1));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getMintPrice(uint tokenIdEx_) public view returns (uint256) {
        uint tokenId_ = tokenIdEx_.sub(_mintStartTokenId);
        uint256 startIndex = 0;
        uint256 endIndex = 0;
        uint256 price = 0;
        for (uint i = 0; i < _issueBatchCount; i++) {
            issueBatchData memory batchData = _issueBatch[i];
            startIndex = batchData.startIndex;
            endIndex = batchData.startIndex.add(batchData.count);
            if(tokenId_ >=startIndex && tokenId_ < endIndex) {
                if(batchData.mintWhite) {
                    price = batchData.whitePrice;
                } else {
                    price = batchData.price;
                }
                break;
            }
        }
        return price;
    }

    function tokenIndex2Batch(uint tokenId_) internal view returns (uint256){
        uint256 startIndex = 0;
        uint256 endIndex = 0;
        uint256 batch = type(uint256).max;
        for (uint i = 0; i < _issueBatchCount; i++) {
            issueBatchData memory batchData = _issueBatch[i];
            startIndex = batchData.startIndex;
            endIndex = batchData.startIndex.add(batchData.count);
            if(tokenId_ >=startIndex && tokenId_ < endIndex) {
                batch = i;
                break;
            }
        }
        return batch;
    }

    function mint(uint numberOfTokens_) public payable nonReentrant{
        uint256 firstId = _mintStartIndex.add(1);
        uint256 batch = tokenIndex2Batch(firstId);
        require(_startMint[batch]&& batch != type(uint256).max, "Mint not start");
        require(_mintStartIndex.add(numberOfTokens_) <= _total_issue, "Mint exceed max issued");
        require(numberOfTokens_ > 0, "At least mint one");
        require(_mintStartIndex.add(numberOfTokens_) < _issueBatch[batch].startIndex.add(_issueBatch[batch].count), "Mint exceed batch issued");
        if(_issueBatch[batch].mintWhite) {
            require(_whitelist[batch][_msgSender()] || owner() == _msgSender(), "Mint only whitelist");
            // owner can mint more
            require(balanceOf(_msgSender()).add(numberOfTokens_)<= _whitelistMintLimit || owner() == _msgSender(), "Exceed whitelist mint limit");
        }
        uint256 total_fee = 0;
        if(_issueBatch[batch].mintWhite) {
            total_fee = _issueBatch[batch].whitePrice.mul(numberOfTokens_);
        } else {
            total_fee = _issueBatch[batch].price.mul(numberOfTokens_);
        }
        require(total_fee <= msg.value, "Insufficient funds");
        //Checks-Effects-Interactions
        _mintStartIndex =_mintStartIndex.add(numberOfTokens_);

        for (uint256 i = 0; i < numberOfTokens_; i++) {
            _safeMint(_msgSender(), firstId.add(i).add(_mintStartTokenId));
        }
    }

    function transferBatch2One(address newOwner_, uint256[] memory tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(_msgSender(), newOwner_, tokenIds_[i]);
        }
    }

    function transferBatch2Many(address [] memory newOwners_, uint256[] memory tokenIds_) external {
        require(newOwners_.length == tokenIds_.length, "array length inconsistent");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(_msgSender(), newOwners_[i], tokenIds_[i]);
        }
    }

    function transferAll2One(address newOwner_) external {
        uint count = balanceOf(_msgSender());
        uint256[] memory newArray = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            newArray[i] = tokenOfOwnerByIndex(_msgSender(), i);
        }
        for (uint256 i = 0; i < count; i++) {
            safeTransferFrom(_msgSender(), newOwner_, newArray[i]);
        }
    }
    
    function mintList() external view returns (uint256[] memory) {
        uint256 count = balanceOf(_msgSender());
        uint256[] memory newArray = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            newArray[i] = tokenOfOwnerByIndex(_msgSender(), i);
        }
        return newArray;
    }
    
    function isMinted(uint256 tokenId_) external view returns (bool) {
        require(
            tokenId_ <= _total_issue.add(_mintStartTokenId),
            "tokenId outside collection bounds"
        );
        return _exists(tokenId_);
    }

    function withdraw() public onlyOwner {
        require(!_withdrawNeedProposal, "Withdraw need proposal");
        uint balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function withdrawAny(uint256 balance_) public onlyOwner {
        require(!_withdrawNeedProposal, "Withdraw need proposal");
        uint balance = address(this).balance;
        require(balance >= balance_, "Insufficient funds");
        Address.sendValue(payable(owner()), balance_);
    }

    function withdrawAnyToOne(uint256 balance_, address beneficiary_) public onlyOwner {
        require(beneficiary_ != address(0), "address zero is not a valid owner");
        require(!_withdrawNeedProposal, "Withdraw need proposal");
        uint balance = address(this).balance;
        require(balance >= balance_, "Insufficient funds");
        Address.sendValue(payable(beneficiary_), balance_);
    }

    function addProposer(address proposer_) external onlyOwner(){
        if(!hasRole(WITHDRAW_ROLE, proposer_)) {
            _withdrawProposerCount = _withdrawProposerCount.add(1);
        }
        _grantRole(WITHDRAW_ROLE, proposer_);
    }

    function removeProposer(address proposer_) external onlyOwner(){
        if(hasRole(WITHDRAW_ROLE, proposer_)) {
            _withdrawProposerCount = _withdrawProposerCount.sub(1);
        }
        _revokeRole(WITHDRAW_ROLE, proposer_);
    }

    function startWithdrawProposer()external onlyOwner(){
        require(_withdrawProposerCount>=_threshold, "need more proposer");
        _withdrawNeedProposal = true;
    }

    function makeProposalForWithdraw(address beneficiary_) public onlyRole(WITHDRAW_ROLE) {
        require(beneficiary_ != address(0), "address zero is not a valid owner");
        require(!_withdrawProposalList[_withdrawProposalCount].execute, "only one proposal on the same time");
        address [] memory supporters=new address[](1);
        supporters[0]=_msgSender();
        _withdrawProposalList[_withdrawProposalCount] = withdrawProposal(_msgSender(), supporters, beneficiary_, false);
        emit makeWithdrawProposal(_msgSender(), beneficiary_, _withdrawProposalCount);
        _withdrawProposalCount = _withdrawProposalCount.add(1);
    }

    function tryExecuteWithdrawProposal(uint256 proposalId_) private {
        address[] memory supporters = _withdrawProposalList[proposalId_].supporters;
        uint supporter_count = supporters.length;
        if(supporter_count>=_threshold && !_withdrawProposalList[proposalId_].execute) {
            uint balance = address(this).balance;
            Address.sendValue(payable(_withdrawProposalList[proposalId_].beneficiary), balance);
            _withdrawProposalList[proposalId_].execute = true;
            emit executeWithdrawProposal(proposalId_);
        }
    }

    function supportProposalForWithdraw(uint256 proposalId_) public onlyRole(WITHDRAW_ROLE) {
        require(proposalId_ < _withdrawProposalCount, "wrong proposalId");
        address[] memory supporters = _withdrawProposalList[proposalId_].supporters;
        for (uint i = 0; i < supporters.length; i++) {
            if(supporters[i]==_msgSender()) {
                return;
            }
        }
        _withdrawProposalList[proposalId_].supporters.push(_msgSender());
        tryExecuteWithdrawProposal(proposalId_);
    }

    function isPresale() external view returns (bool) {
        require(
            _issueBatchCount >= 1,
            "issue nft error"
        );
        return _issueBatch[_issueBatchCount.sub(1)].mintWhite;
    }
}
