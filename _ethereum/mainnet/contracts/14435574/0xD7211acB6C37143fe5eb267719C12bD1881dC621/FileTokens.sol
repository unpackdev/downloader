//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PollyModule.sol";
import "./Meta.sol";

/**

FILE TOKENS v1
A Polly module

*/


interface IFileTokens is IERC721, IPollyModule {

    struct Token {
        string file;
        uint batch;
    }

    struct Batch {
        string file;
        uint begin;
        uint supply;
        uint price;
        address recipient;
    }

    function createBatch(string memory file_, uint amount_, uint begin_, uint price_, address recipient) external;
    function createBatchPremint(string memory file_, uint amount_, uint begin_, uint price_) external;
    function currentBatchIndex() external view returns(uint);
    function getBatch(uint batch_index_) external view returns(IFileTokens.Batch memory);
    function batchAvailable() external view returns(bool);
    function getAvailable() external view returns(uint);
    function leftForAddressInBatch(uint batch_index_, address check_) external view returns(bool);
    function mint(string memory file_) external ;
    function updateTokenFile(uint token_id_, string memory file_) external;
    function setMetaAddress(address meta_) external;
    function getToken(uint token_id_) external view returns(IFileTokens.Token memory);
    function burn(uint token_id_) external;

}

interface IMeta {
    function getMeta(uint token_id_) external view returns(string memory);
}

contract FileTokens is ERC721, ERC721Burnable, PollyModule, ReentrancyGuard {

    uint private _token_ids;
    mapping(uint => IFileTokens.Token) private _tokens;
    mapping(uint => mapping(address => uint)) private _minters;

    uint private _batch;
    mapping(uint => IFileTokens.Batch) private _batches;

    address private _meta;

    modifier onlyHolder(uint tokenID){
        require(ownerOf(tokenID) == msg.sender, 'NOT_TOKEN_HOLDER');
        _;
    }


    //// EVENTS

    event FileUpdated(uint indexed tokenID, string oldUri, string newUri);

    constructor() ERC721("", ""){
    }

    function getModuleInfo() public view returns(IPollyModule.ModuleInfo memory){
        return IPollyModule.ModuleInfo('File Tokens', address(this), true);
    }

    function init(address for_) public override {
        super.init(for_);
    }

    function createBatch(string memory file_, uint amount_, uint begin_, uint price_, address recipient_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        require(amount_ < 10000, 'AMOUNT_EXCEEDS_MAX');

        _batch++;
        _token_ids = 10000*_batch;
        _batches[_batch] = IFileTokens.Batch(
            file_,
            block.timestamp+begin_,
            amount_,
            price_,
            recipient_
        );

    }

    function createBatchPremint(string memory file_, uint amount_, uint begin_, uint price_, address recipient_, address[] memory premints_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        createBatch(file_, amount_, begin_, price_, recipient_);

        if(premints_.length < 1)
            return;

        uint i = 0;
        while(i < premints_.length) {
            _mintTo(premints_[i], '');
            unchecked {++i;}
        }

    }

    function currentBatchIndex() public view returns(uint){
        return _batch;
    }


    function getBatch(uint batch_index_) public view returns(IFileTokens.Batch memory){
        return batch_index_ == 0 ? _batches[_batch] : _batches[batch_index_];
    }


    function batchAvailable() public view returns(bool){
        return (_batch > 0 && block.timestamp > _batches[_batch].begin && getAvailable() > 0);
    }

    function getAvailable() public view returns(uint){
        return _batch > 0 ? _batches[_batch].supply - (_token_ids - (_batch*10000)) : 0;
    }

    function canMintCurrentBatch(address check_) public view returns(bool){
        if(_batch < 1)
            return false;
        uint max = getUint('max_mints');
        if(max == 0)
            return true;
        return (_minters[_batch][check_] < max);

    }

    function mint(string memory file_) public payable nonReentrant {

        IFileTokens.Batch memory batch_ = getBatch(_batch);
        require(batch_.price == msg.value, 'INVALID_VALUE');
        require(batchAvailable(), 'BATCH_UNAVAILABLE');
        require(canMintCurrentBatch(msg.sender), 'MINT_THRESHOLD_EXCEEDED');

        if(batch_.price > 0){
            (bool sent_, ) =  batch_.recipient.call{value: msg.value}("");
            require(sent_, 'TX_FAILED');
        }

        _mintTo(msg.sender, file_);
        
    }

    function _mintTo(address to_, string memory file_) private {
        
        _minters[_batch][to_]++;

        _token_ids++;
        _tokens[_token_ids] = IFileTokens.Token(
            file_,
            _batch
        );

        _mint(to_, _token_ids);

    }

    function name() public view override returns(string memory){
        return getString('name');
    }

    function symbol() public view override returns(string memory){
        return getString('symbol');
    }

    function updateTokenFile(uint token_id_, string memory file_) public onlyHolder(token_id_) {
        string memory oldUri = _tokens[token_id_].file;
        _tokens[token_id_].file = file_;
        emit FileUpdated(token_id_, oldUri, file_);
    }


    function getToken(uint token_id_) public view returns(IFileTokens.Token memory){
        return _tokens[token_id_];
    }

    function tokenURI(uint token_id_) public view override returns(string memory) {
        require(token_id_ <= _token_ids, 'TOKEN_DOES_NOT_EXIST');
        return IMeta(getAddress('meta')).getMeta(token_id_);
    }

    /// Overrides

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
