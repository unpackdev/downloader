// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

// PERSISTENCE ALONE IS OMNIPOTENT!

// S: CHIPAPIMONANO
// A: EMPATHETIC
// F: Pex-Pef
// E: ETHICAL

// ABOUT CREATIVERSE  https://nft.protoverse.ai
// CreatiVerse is a complete, “any-currency” NFT mintpad
// and management platform. It provides creators with sophisticated
// tools to mint, monetize, and fairly distribute NFTs.
// The platform also empowers users with automated
// peer-to-peer NFT scholarships and fixed rental escrows.

// ABOUT PROTOVERSE
// ProtoVerse fulfills projects’ wildest
// NFT and Play-To-Earn game development dreams.

// ProtoVerse’s dApps are custom-built in-house and
// certified by CertiK to ensure the utmost privacy, transparency, and security.
// They can be offered cost-effectively as whitelabel solutions to any qualified project.

// Website: ProtoVerse.ai

//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.,,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@##*.......,,,,,,,,,,,,,,,,,,,,,,*#@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@..............,,,,,,,,,,,,,,,,,,,,,,,,,,,,#@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@%..............                   ..,,,,,,,,,,,,,#@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@(...........                               .,,,,,,,,,,,*@@@@@@@@@@@@
//    @@@@@@@@@&,.........                            ............,,,,,,,***%@@@@@@@@@
//    @@@@@@@@,........                      ........................,,,,*****@@@@@@@@
//    @@@@@@(........               ...................................,,******/@@@@@@
//    @@@@#.......           . .........................,/###(,,,,,,,,,,,,,******/@@@@
//    @@@%.......     .............*(#(*..............,(%%#/%%%(,,,,,,,,,,,*******(@@@
//    @@(....... ................*#%%%%%%*.......,,,,,#&&(,,,#&&#,,,,,,,,,*********,@@
//    @#.........................*%&&&&&%*.,,,,,,,,,,/&@%*,,,*%@@/,,,,,,,***********/@
//    @............................,*/*,,,,,,,,,,,,,,%&@/,,,,,(@@%,,,,,,,************%
//    ........................,(&@@@@&%*,,,,,,,,,,,/@@&,,,,,,,&@@*,,,,,,*************
//    .....................,%@@@@@@@@&@@&/,,,,,,,,,#@&%,,,,,,,#@@(,,,,,,*************
//    .....................&@@&(&@@@@@&&&@@@&*,,,,,,%@@(,,,,,,,(@@%,,,,,,*************
//    ...................*&@&&,,&@&@&@&/.,(&&@&%,,,,%@&(,,,,,,,(&@%,,,,,,*,***********
//    .....................*,../@@@@@@#,,,,,,,,,,,,,#@@#,,,,,,,#@@#,,,,,,*************
//    .........................*%&@@@%*,,,,,,,,,,,,(@&%,,,,,,,&@@(,,,,,,*************
//    @.......................*&&*,/&@&@&(,,,,,,,,,,*@@@*,,,,,/@@@*,,,,,,************#
//    @*......................%@@@&..,%&@@&*,,,,,,,,,#&@(,,,,,#@@#,,,,,,,************&
//    @#....................*&@@@%,...,#@@@%*,,,,,,,,*&@&*,,,*&@&*,,,,,,,***********/@
//    @@@................../&@@@%,.....,&@@@(,,,,,,,,,(&@&*,*&@&(,,,,,,,,***********@@
//    @@@&................#@@@&/.......,*&@@&,,,,,,,,,,*&@&&&@&*,,,,,,,,,*********(@@@
//    @@@@@................/#(.........,,*##*,,,,,,,,,,,,*(%#*,,,,,,,,,,,*,*****,@@@@@
//    @@@@@@%..........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,******/@@@@@@
//    @@@@@@@@@........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,****#@@@@@@@@
//    @@@@@@@@@@%......................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**#@@@@@@@@@@
//    @@@@@@@@@@@@@,...................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@(................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@/,...........,,,,,,,,,,,,,,,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@%(......,,,,,,,,,,,,,,,,,,,,/#%@@@@@@@@@@@@@@@@@@@@@@@@

import "./AppType.sol";
import "./App.sol";
import "./Batch.sol";

/// @custom:security-contact dao@protoverse.ai
contract CreatiVerse {
    using App for AppType.State;
    using BatchFactory for AppType.State;
    AppType.State internal state;

    constructor(
        address dao,
        address feeWallet,
        uint256 chainId
    ) {
        state.initialize(dao, feeWallet, chainId);
    }

    function safeMint(
        AppType.NFT calldata nft,
        AppType.Pass calldata pass,
        AppType.Proof calldata proof
    ) external payable {
        uint256 newTokenId = state.authorizeMint(nft, pass, proof);
        INFT(state.batches[nft.batchId].collection).safeMint(
            msg.sender,
            newTokenId,
            nft.uri
        );
    }

    function setTierSwapAmount(
        uint256 tierId,
        address[] calldata swapTokens,
        uint256[] calldata swapAmounts
    ) external {
        state.setTierSwapAmount(tierId, swapTokens, swapAmounts);
    }

    function getTierSwapAmount(uint256 tierId, address swapToken)
        external
        view
        returns (uint256)
    {
        return state.tierSwapAmounts[tierId][swapToken];
    }

    function changeConfig(
        AppType.IConfigKey calldata key,
        AppType.IConfigValue calldata value
    ) external {
        state.changeConfig(key, value);
    }

    function getConfig(
        AppType.AddressConfig addressConfig,
        AppType.UintConfig uintConfig,
        AppType.BoolConfig boolConfig,
        AppType.StringConfig stringConfig
    )
        external
        view
        returns (
            address addressValue,
            uint256 uintValue,
            bool boolValue,
            string memory stringValue
        )
    {
        return
            state.getConfig(
                addressConfig,
                uintConfig,
                boolConfig,
                stringConfig
            );
    }

    function createBatch(
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) external {
        state.createBatch(kind, isOpenAt, disabled, root, collection);
    }

    function updateBatch(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) external {
        state.updateBatch(batchId, isOpenAt, disabled, root, collection);
    }

    function readBatch(uint256 batchId)
        external
        view
        returns (
            AppType.BatchKind kind,
            uint256 isOpenAt,
            bool disabled,
            bytes32 root
        )
    {
        return state.readBatch(batchId);
    }

    function excludeNFTLeaf(AppType.NFT calldata nft, bool isExcluded)
        external
    {
        state.excludeNFTLeaf(nft, isExcluded);
    }

    function excludePassLeaf(AppType.Pass calldata pass, bool isExcluded)
        external
    {
        state.excludePassLeaf(pass, isExcluded);
    }

    function name() public view returns (string memory) {
        return state.config.strings[AppType.StringConfig.APP_NAME];
    }

    function withdrawDAO(address token, uint256 amount) external {
        state.safeWithdraw(token, amount);
    }
}

interface INFT {
    function safeMint(
        address to,
        uint256 newTokenId,
        string calldata uri
    ) external;
}
