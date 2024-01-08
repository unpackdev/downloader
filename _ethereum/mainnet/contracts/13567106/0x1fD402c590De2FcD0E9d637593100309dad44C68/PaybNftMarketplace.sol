//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <=0.8.6;

import "./ERC721.sol";
import "./IERC20.sol";
import "./IERC721Pausable.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract PaybNftMarketplace is ERC721, IERC721Pausable{
    using Address for address;
    using SafeMath for uint256;

    event PriceChanged(uint256 _tokenId, uint256 _price, address _tokenAddress, address _user);
    event RoyaltyChanged(uint256 _tokenId, uint256 _royalty, address _user);
    event FundsTransfer(uint256 _tokenId, uint256 _amount, address _user);

    mapping(uint256 => bool) tokenStatus;

    mapping(uint256 => uint256) prices;

    mapping(uint256 => address) tokenAddress;

    mapping(uint256 => uint256) royalties; // in decimals (min 0.01%, max 100%)

    mapping(uint256 => address) tokenCreators;

    mapping(address => uint256[]) creatorsTokens;

    uint256 tokenId;

    uint256 platformFee = 0;

    constructor(string memory name_, string memory symbol_, address payable owner_, address admin_) ERC721(name_, symbol_) {
        tokenId = 1;
        owner = owner_;
        admins[admin_] = true;
    }

    function withdraw() external onlyOwner() {
        owner.transfer(getBalance());
    }

    function withdraw(address _user, uint256 _amount) external onlyOwner() {
        uint256 _balance = getBalance();
        require(_balance > 0, "Balance is null");
        require(_balance >= _amount, "Amount is greater than the balance of contract");

        payable(_user).transfer(_amount);
    }

    function withdraw(address _tokenErc20, address _user) external onlyOwner() {
        require(_tokenErc20.isContract(), "Token address isn`t a contract address");
        uint256 _totalBalance = IERC20(_tokenErc20).balanceOf(address(this));

        require(_totalBalance > 0, "Total balance is zero");

        IERC20(_tokenErc20).transfer(_user, _totalBalance);
    }

    function setPlatformFee(uint256 _newFee) public onlyAdmin {
        require(_newFee < 10000, "Royalty can be 100 percent of the total amount");
        platformFee = _newFee;
    }

    function getPlatformFee() public view returns(uint256) {
        return platformFee;
    }

    function getBalance() public view returns(uint256){
        address _self = address(this);
        uint256 _balance = _self.balance;
        return _balance;
    }

    function mint(address _to, address _token, uint256 _price, string memory _uri, uint256 _royalty) public payable {
        require(_token == address(0) || _token.isContract(), "Token address isn`t a contract address");
        require(_royalty + platformFee < 10000, "Creator royalty plus platform fee must be less than 100%");

        prices[tokenId] = _price;
        tokenAddress[tokenId] = _token;
        tokenStatus[tokenId] = true;
        royalties[tokenId] = _royalty;
        tokenCreators[tokenId] = _to;
        creatorsTokens[_to].push(tokenId);

        if((isAdmin(msg.sender) && msg.sender != _to) || msg.sender == address(this)){
            _pause(tokenId);
        }

        _safeMint(_to, tokenId, _uri);

        emit PriceChanged(tokenId++, _price, _token, msg.sender);
    }

    function setPriceAndSell(uint256 _tokenId, uint256 _price) public tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "Sender isn`t owner of token");

        prices[_tokenId] = _price;
        _resume(_tokenId);

        emit PriceChanged(_tokenId, _price, tokenAddress[_tokenId], msg.sender);
    }

    function buy(uint256 _tokenId) public payable tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(tokenStatus[_tokenId], "Token not for sale");
        require(ownerOf(_tokenId) != msg.sender, "Sender is already owner of token");

        uint256 _price = prices[_tokenId];
        uint256 _creatorRoyalty = (_price.mul(royalties[_tokenId])).div(10000);
        uint256 _platformFee = (_price.mul(platformFee)).div(10000);

        if(tokenAddress[_tokenId] == address(0)) {
            require(_price == msg.value, "Value isn`t equal to price!");
            payable(ownerOf(_tokenId)).transfer(_price.sub(_creatorRoyalty + _platformFee));
            payable(tokenCreators[_tokenId]).transfer(_creatorRoyalty);
            owner.transfer(_platformFee);
        }else {
            require(IERC20(tokenAddress[_tokenId]).balanceOf(msg.sender) >= _price, "Insufficient funds");
            IERC20(tokenAddress[_tokenId]).transferFrom(msg.sender, address(this), _price);

            IERC20(tokenAddress[_tokenId]).transfer(ownerOf(_tokenId), _price.sub(_creatorRoyalty + _platformFee));
            IERC20(tokenAddress[_tokenId]).transfer(owner, _platformFee);
            IERC20(tokenAddress[_tokenId]).transfer(tokenCreators[_tokenId], _creatorRoyalty);
        }

        _pause(_tokenId);

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function balanceOf(address _user, uint256 _tokenId) public view returns(uint256) {
        return IERC20(tokenAddress[_tokenId]).balanceOf(_user);
    }

    function getPriceInTokens(uint256 _tokenId) public view tokenNotFound(_tokenId) isUnlock(_tokenId) returns(uint256, address){
        return (prices[_tokenId], tokenAddress[_tokenId]);
    }

    function pause(uint256 _tokenId) external override tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "User isn`t owner of token!");

        _pause(_tokenId);
    }

    function _pause(uint256 _tokenId) internal {
        tokenStatus[_tokenId] = false;

        emit Paused(_tokenId);
    }

    function resume(uint256 _tokenId) external override tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "User isn`t owner of token!");

        _resume(_tokenId);
    }

    function _resume(uint256 _tokenId) internal {
        tokenStatus[_tokenId] = true;

        emit Resumed(_tokenId);
    }

    function getTokenStatus(uint256 _tokenId) public view returns(bool) {
        return isLock(_tokenId);
    }

    function isForSale(uint256 _tokenId) public view returns(bool) {
        return tokenStatus[_tokenId];
    }

    function getRoyalty(uint256 _tokenId) public view returns(uint256) {
        return royalties[_tokenId];
    }

    function setNewRoyalty(uint256 _tokenId, uint256 _newRoyalty) public tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(msg.sender == ownerOf(_tokenId), "Sender isn`t an owner of token");
        require(_newRoyalty > royalties[_tokenId] && _newRoyalty <= 10000 && _newRoyalty + platformFee <= 10000, "New royalty cannot be less than the old one or more than 100%");

        royalties[_tokenId] = _newRoyalty;

        emit RoyaltyChanged(_tokenId, _newRoyalty, msg.sender);
    }

    function sendToken(uint256 _tokenId, address _from, address _to) public tokenNotFound(_tokenId) onlyAdmin() {
        require(isLock(_tokenId), "Token is unlocked");
        _transfer(_from, _to, _tokenId);
        _unlock(_tokenId);
        _pause(_tokenId);
    }

    function sendTo(uint256 _tokenId, address payable _to) public onlyAdmin() tokenNotFound(_tokenId) payable{
        require(ownerOf(_tokenId) == _to, "To isn`t an owner of token");

        uint256 _price = prices[_tokenId];
        address _token = tokenAddress[_tokenId];


        uint256 _creatorRoyalty = (_price.mul(royalties[_tokenId])).div(10000);
        uint256 _platformFee = (_price.mul(platformFee)).div(10000);

        if(_token == address(0)){
            require(_price == msg.value, "Amount isn`t equal to price");
            _to.transfer(_price.sub(_creatorRoyalty + _platformFee));
            payable(tokenCreators[_tokenId]).transfer(_creatorRoyalty);
            owner.transfer(_platformFee);
        }else {
            require(IERC20(_token).balanceOf(msg.sender) >= _price, "Insufficient funds");
            IERC20(_token).transferFrom(msg.sender, _to, _price.sub(_creatorRoyalty + _platformFee));
            IERC20(_token).transferFrom(msg.sender, tokenCreators[_tokenId], _creatorRoyalty);
        }

        _lock(_tokenId);
        _pause(_tokenId);
    }

    function sendToAdmin(address _token, address _admin, uint256 _amount, uint256 _tokenId) public payable{
        require(_token.isContract() || _token == address(0), "Token isn`t a contract address");

         if(_token == address(0)){
            payable(_admin).transfer(msg.value);
        }else {
            require(IERC20(_token).balanceOf(msg.sender) >= _amount, "Insufficient funds");
            IERC20(_token).transferFrom(msg.sender, _admin, _amount);
        }

        emit FundsTransfer(_tokenId, _amount == 0? msg.value : _amount, msg.sender);
    }

    function getAllTokensObjs() public view returns(Token[] memory) {
        Token[] memory _tokensObj = new Token[](_allTokens.length);

        uint256 _id = 1;
        while(_allTokens.length >= _id){
            Token memory _token = Token({
                id:    _id,
                price: prices[_id],
                token: tokenAddress[_id],
                owner: _owners[_id],
                creator: tokenCreators[_id],
                uri:   _tokenURIs[_id],
                status: isForSale(_id),
                isLocked: isLock(_id)
            });

            _tokensObj[_id-1] = _token;
            _id++;
        }

        return _tokensObj;
    }

    function getAllTokensByPage(uint256 _from, uint256 _to) public view returns(Token[] memory) {
        require(_from < _to, "From is bigger than to");

        uint256 _last = (_to > _allTokens.length) ? _allTokens.length : _to;

        Token[] memory _tokens = new Token[](_to-_from + 1);

        uint256 _j = 0;

        for(uint256 i=_from; i<=_last; i++) {
            Token memory _token = Token({
                id:    i,
                price: prices[i],
                token: tokenAddress[i],
                owner: _owners[i],
                creator: tokenCreators[i],
                uri:   _tokenURIs[i],
                status: isForSale(i),
                isLocked: isLock(i)
            });

            _tokens[_j++] = _token;
        }

        return _tokens;
    }

    function getTokensByUserObjs(address _user) public view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](_balances[_user]);

        for(uint256 i=0; i<_tokens.length; i++) {
            if(_ownedTokens[_user][i] != 0) {
                uint256 _tokenId = _ownedTokens[_user][i];
                Token memory _token = Token({
                    id:    _tokenId,
                    price: prices[_tokenId],
                    token: tokenAddress[_tokenId],
                    owner: _user,
                    creator: tokenCreators[_tokenId],
                    uri:   _tokenURIs[_tokenId],
                    status: isForSale(_tokenId),
                    isLocked: isLock(_tokenId)
                });

                _tokens[i] = _token;
            }
        }

        return _tokens;
    }

    function getTokenInfo(uint256 _tokenId) public view returns(Token memory) {
        Token memory _token = Token({
            id: _tokenId,
            price: prices[_tokenId],
            token: tokenAddress[_tokenId],
            owner: _owners[_tokenId],
            creator: tokenCreators[_tokenId],
            uri: _tokenURIs[_tokenId],
            status: isForSale(_tokenId),
            isLocked: isLock(_tokenId)
        });

        return _token;
    }

    function getCreatorsTokens(address _creator) public view returns(uint256[] memory) {
        return creatorsTokens[_creator];
    }

    function getCreatorsTokensObj(address _creator) public view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](creatorsTokens[_creator].length);

        for(uint256 i=0; i<_tokens.length; i++) {
            uint256 _tokenId = creatorsTokens[_creator][i];
            Token memory _token = Token({
                id: _tokenId,
                price: prices[_tokenId],
                token: tokenAddress[_tokenId],
                owner: _owners[_tokenId],
                creator: _creator,
                uri: _tokenURIs[_tokenId],
                status: isForSale(_tokenId),
                isLocked: isLock(_tokenId)
            });

            _tokens[i] = _token;
        }


        return _tokens;
    }
}