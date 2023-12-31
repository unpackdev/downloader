// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./ERC1155.sol";
import "./Owned.sol";
import "./FeeController.sol";
import "./ReentrancyGuard.sol";

contract FoxAndGary is ERC1155, Owned, FeeController, ReentrancyGuard {

    string public constant name = "Fox And Gary";
    string public constant symbol = "FNG";

    uint256 public constant mintPriceStep = 100 gwei; // 0.0000001 ether
    uint256 public lastMintPrice;
    uint256 public supply;

    uint256 public treasury;

    struct UriUpdate {string uri; uint256 unlock;}
    UriUpdate public uriUpdate;
    string private _uri;

    constructor(address _owner, string memory uri_, address[4] memory feeRecipients_)
    Owned(_owner) FeeController(feeRecipients_) {
        uriUpdate = UriUpdate(uri_, 0);
        _uri = uri_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(id == 1, "token does not exist");
        return _uri;
    }

    // MINT / BURN

    function mint(address _to, uint256 _amount, bytes memory _data) public payable nonReentrant {
        uint256 batchValue_ = batchValue(_amount);
        require(msg.value >= batchValue_, "wrong value provided");

        uint256 fee_ = batchValue_ * 40 / 1000;
        _distributeFees(fee_);
        treasury += batchValue_ - fee_;

        uint256 supply_ = supply + _amount;
        lastMintPrice = supply_ * mintPriceStep;
        supply = supply_;
        _mint(_to, 1, _amount, _data);
    }

    function burn(uint256 _amount) public nonReentrant {
        require(balanceOf[msg.sender][1] >= _amount, "not enough tokens");
        uint256 buyoutValue_ = buyoutValue(_amount);
        uint256 supply_ = supply - _amount;
        lastMintPrice = supply_ * mintPriceStep;
        supply = supply_;
        treasury -= buyoutValue_;
        _burn(msg.sender, 1, _amount);
        (bool sent,) = (msg.sender).call{value: buyoutValue_}("");
        require(sent);
    }

    function buyoutValue(uint256 _amount) public view returns (uint256) {
        require(_amount > 0);
        if (supply == 0) return 0;
        return _amount * treasury / supply;
    }

    function batchValue(uint256 _amount) public view returns (uint256) {
        return _amount * (lastMintPrice*2 + mintPriceStep + (_amount * mintPriceStep))/2;
    }

    function prepareUriUpdate(string memory uri_) public onlyOwner {
        uriUpdate = UriUpdate(uri_, block.timestamp + 5 days);
    }

    function setUri() public onlyOwner {
        require(block.timestamp >= uriUpdate.unlock, "uri locked");
        _uri = uriUpdate.uri;
    }
}
