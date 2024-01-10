// Squishiverse by FourLeafClover (www.squishiverse.com) - Staking Contract

// MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
// MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
// MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
// MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
// MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
// MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
// MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
// Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
// KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
// dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
// lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
// cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
// cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
// cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
// olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
// kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
// XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
// M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
// MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
// MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
// MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
// MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
// MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
// MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
// MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
// MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

contract StakeSquishies is Ownable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    // Contract Addresses
    address public immutable erc721Address;

    // Deposit Tracking
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositTimes;

    // Events
    event Deposit(address addr, uint256[] tokenIds);
    event Withdraw(address addr, uint256[] tokenIds);

    constructor(address _erc721Address) {
        erc721Address = _erc721Address;
    }

    /**
     * Track deposits of an account
     */
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());
        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }
        return tokenIds;
    }

    /**
     * Get the deposits information as an array of packed byte strings
     */
    function depositsOfAdvanced(address account)
        external
        view
        returns (bytes[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        bytes[] memory depositTimes = new bytes[](depositSet.length());
        for (uint256 i; i < depositSet.length(); i++) {
            uint256 tokenId = depositSet.at(i);
            depositTimes[i] = abi.encodePacked(
                tokenId,
                _depositTimes[account][tokenId]
            );
        }
        return depositTimes;
    }

    /**
     * Deposit Squishies into the contract
     */
    function deposit(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(erc721Address).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );
            _depositTimes[msg.sender][tokenIds[i]] = block.timestamp;
            _deposits[msg.sender].add(tokenIds[i]);
        }
        emit Deposit(msg.sender, tokenIds);
    }

    /**
     * Withdraw Squishies from the contract
     */
    function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Token not deposited"
            );
            _deposits[msg.sender].remove(tokenIds[i]);
            IERC721(erc721Address).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
        emit Withdraw(msg.sender, tokenIds);
    }

    /**
     * Allows contract owner to withdraw some token from the contract
     */
    function withdrawTokens(IERC20 erc20Address) external onlyOwner {
        uint256 tokenSupply = erc20Address.balanceOf(address(this));
        erc20Address.transfer(msg.sender, tokenSupply);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
