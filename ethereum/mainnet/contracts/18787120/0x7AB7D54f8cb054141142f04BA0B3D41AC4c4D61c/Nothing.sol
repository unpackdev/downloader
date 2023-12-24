// SPDX-License-Identifier: MIT

/*********************************************************************


                                                        ,/
                                                        //
                                                    ,//
                                        ___   /|   |//
                                    `__/\_ --(/|___/-/
                                \|\_-\___ __-_`- /-/ \.
                                |\_-___,-\_____--/_)' ) \
                                \ -_ /     __ \( `( __`\|
                                `\__|      |\)\ ) /(/|
        ,._____.,            ',--//-|      \  |  '   /
        /     __. \,          / /,---|       \       /
        / /    _. \  \        `/`_/ _,'        |     |
        |  | ( (  \   |      ,/\'__/'/          |     |
        |  \  \`--, `_/_------______/           \(   )/
        | | \  \_. \,                            \___/\
        | |  \_   \  \                                 \
        \ \    \_ \   \   /                             \
        \ \  \._  \__ \_|       |                       \
        \ \___  \      \       |                        \
        \__ \__ \  \_ |       \                         |
        |  \_____ \  ____      |                        |
        | \  \__ ---' .__\     |        |               |
        \  \__ ---   /   )     |        \              /
            \   \____/ / ()(      \          `---_       /|
            \__________/(,--__    \_________.    |    ./ |
            |     \ \  `---_\--,           \   \_,./   |
            |      \  \_ ` \    /`---_______-\   \\    /
                \      \.___,`|   /              \   \\   \
                \     |  \_ \|   \              (   |:    |
                \    \      \    |             /  / |    ;
                \    \      \    \          ( `_'   \  |
                    \.   \      \.   \          `__/   |  |
                    \   \       \.  \                |  |
                    \   \        \  \               (  )
                        \   |        \  |              |  |
                        |  \         \ \              I  `
                        ( __;        ( _;            ('-_';
                        |___\        \___:            \___:


*********************************************************************/
/********************************************************************* 


                                                    ,--,  ,.-.
                    ,                   \,       '-,-`,'-.' | ._
                    /|           \    ,   |\         }  )/  / `-,',
                    [ ,          |\  /|   | |        /  \|  |/`  ,`
                    | |       ,.`  `,` `, | |  _,...(   (      .',
                    \  \  __ ,-` `  ,  , `/ |,'      Y     (   /_L\
                    \  \_\,``,   ` , ,  /  |         )         _,/
                        \  '  `  ,_ _`_,-,<._.<        /         /
                        ', `>.,`  `  `   ,., |_      |         /
                        \/`  `,   `   ,`  | /__,.-`    _,   `\
                    -,-..\  _  \  `  /  ,  / `._) _,-\`       \
                        \_,,.) /\    ` /  / ) (-,, ``    ,        |
                    ,` )  | \_\       '-`  |  `(               \
                    /  /```(   , --, ,' \   |`<`    ,            |
                    /  /_,--`\   <\  V /> ,` )<_/)  | \      _____)
            ,-, ,`   `   (_,\ \    |   /) / __/  /   `----`
            (-, \           ) \ ('_.-._)/ /,`    /
            | /  `          `/ \\ V   V, /`     /
        ,--\(        ,     <_/`\\     ||      /
        (   ,``-     \/|         \-A.A-`|     /
        ,>,_ )_,..(    )\          -,,_-`  _--`
        (_ \|`   _,/_  /  \_            ,--`
        \( `   <.,../`     `-.._   _,-`


*********************************************************************/

pragma solidity 0.8.23;

import "./IERC20Metadata.sol";
import "./ERC20.sol";

import "./IUniswapV2Factory.sol";

import "./Transformable.sol";
import "./Common.sol";

/// @title NOTHING contract
/// @notice An ERC20 token
contract Nothing is ERC20, Transformable {
    /// @notice Thrown when transform done is called even after it's done
    error AlreadyTransformed();
    /// @notice Thrown when transform() is called in block having token transfer
    error NotAllowed();
    /// @notice Thrown when unlock() is called and transfers are already unlocked
    error AlreadyUnlocked();

    string private constant NOTHING = "NOTHING";
    string private constant SOMETHING = "SOMETHING";
    uint256 private constant TOTAL_SUPPLY = 311_020_080e18;
    uint256 public lastUpdateBlock;

    bool private _unlocked;
    address private immutable _initialHolder;

    bool public isTransforming;
    bool public isTransformed;

    /// @dev Constructor
    /// @param initHolder The address of the wallet to which initial tokens will be minted
    /// @param baseToken The address of the baseToken token
    /// @param usdt The address of the usdt token
    /// @param factory The uniswap factory contract address
    constructor(
        address initHolder,
        IERC20Metadata baseToken,
        IERC20Metadata usdt,
        IUniswapV2Factory factory
    ) ERC20(NOTHING, NOTHING) Transformable(baseToken, usdt, factory, 1e18) {
        if (
            initHolder == address(0) ||
            address(baseToken) == address(0) ||
            address(usdt) == address(0) ||
            address(factory) == address(0)
        ) {
            revert ZeroAddress();
        }
        _mint(initHolder, TOTAL_SUPPLY);
        _initialHolder = initHolder;
    }

    /// @inheritdoc ERC20
    /// @dev May return nothing or something
    function name() public view override returns (string memory) {
        if (isTransformed) {
            return SOMETHING;
        }
        return super.name();
    }

    /// @inheritdoc ERC20
    /// @dev May return nothing or something
    function symbol() public view override returns (string memory) {
        if (isTransformed) {
            return SOMETHING;
        }
        return super.symbol();
    }

    /// @notice Updates unlocked to true so transfers are enabled
    function unlock() external {
        if (msg.sender != _initialHolder) {
            revert NotAllowed();
        }
        if (_unlocked) {
            revert AlreadyUnlocked();
        }
        _unlocked = true;
    }


    /// @notice Updates name and symbol when the price reaches 1 dollar
    function transform() external {
        if (block.number == lastUpdateBlock) {
            revert NotAllowed();
        }
        if (isTransformed) {
            revert AlreadyTransformed();
        }
        if (!isTransforming) {
            _initTransform();
            isTransforming = true;
        } else {
            if (_finalizeTransform()) {
                isTransformed = true;
            }
            isTransforming = false;
        }
    }

    /// @inheritdoc ERC20
    /// @dev Overridden to store block number on every update
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        uint256 lastBlock = lastUpdateBlock;
        if (lastBlock != block.number) {
            lastUpdateBlock = block.number;
        }
        if (!_unlocked && from != _initialHolder) {
            revert NotAllowed();
        }
        super._update(from, to, value);
    }
}
