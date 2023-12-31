// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";

contract TaiXuNFTExchange is ERC1155, ERC1155Burnable {
    using SafeERC20 for IERC20;
    struct InitialOwner {
        address owner;
        uint256 amount;
    }

    struct InitialNumber {
        address owner;
        uint256 number;
    }

    struct CurrentOwner {
        address owner;
        uint256 amount;
    }

    struct Vote {
        address voter;
        uint256 number;
    }

    mapping(uint256 => InitialOwner) public initialOwners;
    mapping(uint256 => InitialNumber) public initialNumbers;
    mapping(uint256 => CurrentOwner[]) public tokenIdCurrentOwner;
    mapping(uint256 => Vote[]) public voteInfo;
    mapping(uint256 => string) private _uris;
    string public name;
    string public symbol;
    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
    }
    function setURI(string memory newuri) public {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) override public view returns (string memory){
        return (_uris[tokenId]);
    }

    function setTokenUri(uint256 tokenId, string memory uri) public {
        _uris[tokenId] = uri;
    }

    function mint(address account, uint256 id, uint256 number, uint256 amount, string memory uri, bytes memory data) public
    {
        bool result = getNftEXit(id, account);
        require(result != true, "this id had mint");
        _mint(account, id, amount, data);
        initOwnerAmount(account, id, amount);
        initOwnerNumber(account, id, number);
        initCurrentOwner(account, id, amount);
        _uris[id] = uri;
    }


    function transferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public {
        bool result = getVoteInfoExit(id, from);
        if (result == true && msg.sender == from) {
            revert("this address in vote cannot transfer");
        }
        safeTransferFrom(from, to, id, amount, data);
        changeTokenIdAmount(from, to, id, amount);
        if (result == true) {
            removeVoteInfo(id, from);
        }
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public
    {
        _mintBatch(to, ids, amounts, data);
    }

    function initOwnerAmount(address _owner, uint256 tokenId, uint256 _amount) internal {
        InitialOwner memory initialOwner = InitialOwner({
            owner : _owner,
            amount : _amount
            });
        initialOwners[tokenId] = initialOwner;
    }

    function initOwnerNumber(address _owner, uint256 tokenId, uint256 _number) internal {
        InitialNumber memory initialNumber = InitialNumber({
            owner : _owner,
            number : _number
            });
        initialNumbers[tokenId] = initialNumber;
    }

    function decreaseNumber(address owner, uint256 nftNumber, uint256 tokenId, uint256 decNumber) public {
        require(initialNumbers[tokenId].number >= decNumber, "less number to decrease");
        require(balanceOf(owner, tokenId) >= nftNumber, "less nft number to delivery");
        initialNumbers[tokenId].number = initialNumbers[tokenId].number - decNumber;
        _burn(owner, tokenId, nftNumber);
    }

    function initCurrentOwner(address _owner, uint256 tokenId, uint256 _amount) internal {
        CurrentOwner memory currentOwner = CurrentOwner({
            owner : _owner,
            amount : _amount
            });
        tokenIdCurrentOwner[tokenId].push(currentOwner);
    }


    function changeTokenIdAmount(address _from, address _to, uint256 _tokenId, uint256 _amount) internal {
        if (getShareExit(_tokenId, _to)) {
            CurrentOwner memory currentOwner = getShareEntity(_tokenId, _to);
            currentOwner.amount += _amount;

            uint256 shareIndex = getShareArrayIndex(_tokenId, _to);
            tokenIdCurrentOwner[_tokenId][shareIndex] = currentOwner;
        } else {
            CurrentOwner memory currentOwner = CurrentOwner({
                owner : _to,
                amount : _amount
                });
            tokenIdCurrentOwner[_tokenId].push(currentOwner);
        }

        CurrentOwner memory current = getShareEntity(_tokenId, _from);
        current.amount = current.amount - _amount;

        uint256 shareOneIndex = getShareArrayIndex(_tokenId, _from);
        tokenIdCurrentOwner[_tokenId][shareOneIndex] = current;
    }

    function getShareExit(uint256 _tokenId, address owner) internal view returns (bool){
        CurrentOwner[] memory shares = tokenIdCurrentOwner[_tokenId];
        for (uint i = 0; i < shares.length; i++) {
            if (shares[i].owner == owner) {
                return true;
            }
        }
        return false;
    }

    function getShareEntity(uint256 _tokenId, address owner) internal view returns (CurrentOwner memory){
        CurrentOwner  memory share;
        CurrentOwner[] memory shareList = tokenIdCurrentOwner[_tokenId];
        for (uint i = 0; i < shareList.length; i++) {
            if (shareList[i].owner == owner) {
                share = shareList[i];
                return share;
            }
        }
        return share;
    }

    function getShareArrayIndex(uint256 _tokenId, address owner) internal view returns (uint256){
        uint256 index;
        CurrentOwner[] memory shareList = tokenIdCurrentOwner[_tokenId];
        for (uint i = 0; i < shareList.length; i++) {
            if (shareList[i].owner == owner) {
                index = i;
                return index;
            }
        }
        return index;
    }

    function acquisition(address owner, address operator, uint256 id) public {
        addVoteInfo(owner, operator, id);
    }

    function addVoteInfo(address voter, address operator, uint256 id) public {
        uint256 _number = balanceOf(voter, id);
        Vote memory newVote = Vote({
            voter : voter,
            number : _number
            });
        voteInfo[id].push(newVote);
        _setApprovalForAll(voter, operator, true);
    }

    function approvalForAll(address owner, address operator) public virtual {
        _setApprovalForAll(owner, operator, true);
    }

    function approvedForAll(address account, address operator) public view virtual returns (bool) {
        return isApprovedForAll(account, operator);
    }

    function getVoteInfo(uint256 id) public view returns (uint256, uint256){
        uint256 all = initialOwners[id].amount;
        uint256 realVoteNumber = 0;
        Vote[] memory voteList = voteInfo[id];
        for (uint i = 0; i < voteList.length; i++) {
            realVoteNumber += voteList[i].number;
        }
        return (all, realVoteNumber);
    }

    function removeVoteInfo(uint256 id, address voter) internal {
        Vote[] memory voteList = voteInfo[id];
        for (uint i = 0; i < voteList.length; i++) {
            if (voteList[i].voter == voter) {
                delete voteList[i];
            }
        }

    }

    function getVoteInfoExit(uint256 id, address voter) public view returns (bool){
        Vote[] memory voteList = voteInfo[id];
        for (uint i = 0; i < voteList.length; i++) {
            if (voteList[i].voter == voter) {
                return true;
            }
        }
        return false;
    }

    function getNftEXit(uint256 id, address owner) public view returns (bool){
        if (initialOwners[id].owner == owner) {
            return true;
        }
        return false;
    }

    function getVoteInfoResult(uint256 id) public view returns (bool){
        uint256 all = initialOwners[id].amount;
        uint256 realVoteNumber = 0;
        bool result = false;
        Vote[] memory voteList = voteInfo[id];
        for (uint i = 0; i < voteList.length; i++) {
            realVoteNumber += voteList[i].number;
        }
        uint256 per = calculatePercentage(realVoteNumber, all);
        uint256 standard = calculatePercentage(2, 3);
        if (per > standard) {
            result = true;
        }
        if (per <= standard) {
            result = false;
        }
        return result;
    }

    function calculatePercentage(uint256 numerator, uint256 denominator) public pure returns (uint256) {
        require(denominator != 0, "Denominator must be a non-zero value");
        uint256 percentage = (numerator * 100) / denominator;
        return percentage;
    }


    function deposit() public payable {
    }

    function withdraw(address payable rec, uint256 amount) public {
        address contractAddress = address(this);
        require(contractAddress.balance > amount, "less amount to withdraw");
        rec.transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


}

