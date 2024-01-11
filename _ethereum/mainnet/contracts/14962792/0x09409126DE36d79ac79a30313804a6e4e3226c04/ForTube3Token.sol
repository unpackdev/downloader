// SPDX-License-Identifier: MIT
// ForTube2.0 Contracts v1.2

pragma solidity ^0.8.1;

import "./ERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./IForTube3Token.sol";

contract ForTube3Token is ERC20, IForTube3Token, Ownable {

    address private _promoterPass;
    uint256 private _maxSupply;
    uint256 private _passSupplyPerBlock;
    uint256 private _padSupply;
    uint256 private _teamSupply;
    uint256 private _allocatedToTeam;
    uint256 private _allocatedToPromoterPass;  
    uint256 private _allocatedToPad;
    
    
    mapping(uint256 => uint256) private _minedAmounts;
    mapping(uint256 => uint256) private _miningAmounts;
    mapping(uint256 => uint256) private _miningStartBlocks;

    uint256 private _miningAmountForNormal;
    uint256 private _miningAmountForLimited;
    uint256 private _maxLimitedTokenId;
    uint256 private _stakingStartBlock;
    uint256 private _stakingBreakBlock;

    constructor()
    ERC20("ForTube3.0 Token","FOT")
    {
        _miningAmountForNormal = 0.002 ether;
        _miningAmountForLimited = _miningAmountForNormal * 2;
        _maxSupply = 1000000000 ether;
        _allocatedToTeam = _maxSupply / 10;
        _allocatedToPromoterPass = _maxSupply * 3 / 10;
        _allocatedToPad = _maxSupply - _allocatedToTeam - _allocatedToPromoterPass;
        _maxLimitedTokenId = 1000;
    }

    function mintByPassNFT(uint256 tokenId) public {
        
        require(IERC721(_promoterPass).ownerOf(tokenId) == msg.sender, "FOT : caller is not owner");
        require(_stakingStartBlock != 0 && _stakingStartBlock <= block.number, "FOT : staking is paused");
        require(_stakingBreakBlock != 0 && _miningStartBlocks[tokenId] <= _stakingBreakBlock , "FOT : staking was finished");
        _mintByPromoterPass(msg.sender, tokenId);

    }

    function mintByTransferring(uint256 tokenId) public override onlyPromoterPass {

        if( _stakingBreakBlock != 0 && _miningStartBlocks[tokenId] <= _stakingBreakBlock ){
            address owner = IERC721(_promoterPass).ownerOf(tokenId);
            require(owner != address(0), "FOT : owner is invalid");
            _mintByPromoterPass(owner, tokenId);
        }
    }

    function _mintByPromoterPass(address to, uint256 tokenId) private {
        
        require( _miningStartBlocks[tokenId] != 0 && _miningStartBlocks[tokenId] < block.number, "FOT : invalid blocknumber");
        require( _miningAmounts[tokenId] == _miningAmountForNormal || _miningAmounts[tokenId] == _miningAmountForLimited, "FOT : invalid amount");
        
        uint256 minedAmount = _calMiningAmounts(tokenId);
        if(minedAmount != 0){
            _mint(to, minedAmount );
            _miningStartBlocks[tokenId] = block.number + 1;
            _minedAmounts[tokenId] += minedAmount; 

            emit MiningLog( tokenId, to, _miningAmounts[tokenId], _minedAmounts[tokenId], _miningStartBlocks[tokenId]);
        }
    }

    function addMining(uint256 tokenId, address owner) public override onlyPromoterPass {

        if(tokenId == 1){
            _stakingBreakBlock = block.number + _allocatedToPromoterPass / (_miningAmountForNormal * _maxLimitedTokenId * 9 + _miningAmountForLimited * _maxLimitedTokenId) + 1;
        }

        if(_stakingBreakBlock >= block.number){
            if(tokenId <= _maxLimitedTokenId){
                _miningAmounts[tokenId] = _miningAmountForLimited;
            }else{
                _miningAmounts[tokenId] = _miningAmountForNormal;
            }
            _passSupplyPerBlock += _miningAmounts[tokenId];
        }

        _miningStartBlocks[tokenId] = block.number;
        
        emit MiningLog( tokenId, owner, _miningAmounts[tokenId], 0, _miningStartBlocks[tokenId]);

    }

    function mintByTeam(uint256 value) public onlyOwners {
        require( _allocatedToTeam >= _teamSupply + value, "FOT : exceeded max supply for TEAM" );
        _mint(owners(0), value );
        _teamSupply += value;
    }

    function mintByPad(address[] memory owners, uint256[] memory amounts) public override onlyOwners {

        require( owners.length == amounts.length, "FOT : array size mismatch" );

        for (uint256 i = 0; i < owners.length; i++) {
            require( _allocatedToPad >= _padSupply + amounts[i], "FOT : exceeded max supply for PAD" );
            _padSupply += amounts[i];
            _mint(owners[i], amounts[i]);
        }
    }

    function setStakingStartBlockNumber(uint256 blockNumber) public onlyOwners {
        _stakingStartBlock = blockNumber;
    }

    function setStakingBreakBlockNumber(uint256 blockNumber) public onlyOwners {
        _stakingBreakBlock = blockNumber;
    }

    function setPromoterPass(address newContract) public onlyOwner {
        _promoterPass = newContract;
    }

    function passSupplyPerBlock() public view returns (uint256) {
        return _passSupplyPerBlock;
    }

    function padSupply() public view returns (uint256) {
        return _padSupply;
    }

    function teamSupply() public view returns (uint256) {
        return _teamSupply;
    }

    function _calMiningAmounts(uint256 tokenId) private view returns (uint256) {

        if( _miningStartBlocks[tokenId] > _stakingBreakBlock ){
            return 0;
        }

        if( _stakingBreakBlock <= block.number ){
            return _miningAmounts[tokenId] * (_stakingBreakBlock - _miningStartBlocks[tokenId] + 1);
        }

        return _miningAmounts[tokenId] * (block.number - _miningStartBlocks[tokenId] + 1);
    }

    function miningInfo(uint256 tokenId) public view returns (uint256, uint256, uint256, uint256) {
        return (_miningAmounts[tokenId], _miningStartBlocks[tokenId], _calMiningAmounts(tokenId), _minedAmounts[tokenId]);
    }

    function stakingStartBlockNumber() public view returns (uint256){
        return _stakingStartBlock;
    }

    function stakingBreakBlock() public view returns (uint256){
        return _stakingBreakBlock;
    }
    
    function promoterPass() public view returns (address){
        return _promoterPass;
    }

    function _beforeTokenTransfer( address from, address to, uint256 amount ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if(from == address(0)){
            require( _maxSupply >= totalSupply() + amount , "FOT : exceeded max supply"  );
        }
    }

    modifier onlyPromoterPass() {
        require(_promoterPass == msg.sender, "FOT : caller is not offical contract");
        _;
    }

}