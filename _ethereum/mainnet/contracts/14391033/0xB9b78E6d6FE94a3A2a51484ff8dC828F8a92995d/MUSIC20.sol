// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract MUSIC20 is ERC20, Ownable {
    mapping(address => bool) public transferWhiteMap;
    mapping(address => bool) public transferBlackMap;

    uint256 public openTransferTime;

    event SetTransferWhite(address indexed user, bool flag);
    event SetTransferBlack(address indexed user, bool flag);
    event SetOpenTransferTime(uint256 openTransferTime);

    constructor(address holder, uint256 _openTransferTime)
        ERC20("MusicY", "MY")
    {
        openTransferTime = _openTransferTime;
        transferWhiteMap[msg.sender] = true;
        transferWhiteMap[holder] = true;
        _mint(holder, 100 * 1e8 * 1e18);
    }

    function setTransferWhiteMap(address[] memory users, bool[] memory flags)
        external
        onlyOwner
    {
        require(
            users.length == flags.length,
            "MUSIC20#setTransferWhiteMap: length mismatch"
        );
        for (uint256 i = 0; i < users.length; i++) {
            transferWhiteMap[users[i]] = flags[i];
            emit SetTransferWhite(users[i], flags[i]);
        }
    }

    function setTransferBlackMap(address[] memory users, bool flag)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            transferBlackMap[users[i]] = flag;
            emit SetTransferBlack(users[i], flag);
        }
    }

    function setOpenTransferTime(uint256 _openTransferTime) external onlyOwner {
        require(
            _openTransferTime > block.timestamp,
            "MUSIC20#setOpenTransferTime: openTransferTime should grater than now"
        );
        openTransferTime = _openTransferTime;
        emit SetOpenTransferTime(openTransferTime);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (
            openTransferTime > block.timestamp &&
            (!transferWhiteMap[from] && !transferWhiteMap[to])
        ) {
            revert(
                "MUSIC20#_beforeTokenTransfer: please wait until the openTransferTime"
            );
        }
        if (transferBlackMap[from] || transferBlackMap[to]) {
            revert("MUSIC20#_beforeTokenTransfer: transfer is forbidden");
        }
    }
}
