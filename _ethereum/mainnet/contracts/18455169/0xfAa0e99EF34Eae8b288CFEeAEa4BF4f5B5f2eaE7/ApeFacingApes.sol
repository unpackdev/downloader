// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Strings.sol";

//                                                  :
//                                              .=*#=--=-
//                                     .:-=++*%@@@@@@@@#=:.
//                              -=*#%@@@@@@@@@@@@@@@@@@@@@@@%*-
//                           =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//             .:..        :%@@@@@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@.
//          =%@@@@@@#-    +@@@@%+-.. .:=+#%@@@@@@@#+:      :+@@@@%         :---.
//        .%@@@@@@@@@@%:.#@@@%-             :*@=:            .#@@@*    .+%@@@@@@@+
//        %@@@@%@@@@@@@@@@@@%    .::::::::.   =   :::::::::.   #@@@- .*@@@@@@@@%@@%:
//       *@@#.    :+@@@@@@@@.  .-          +.   :=         .-  .@@@%*@@@@@#=:   +@@@:
//      -@@%  .::::::+%@@@@=  ::           -  .  -           -. *@@@@@@#=-:::.  .@@@*
//     .@@@+ .  :      +@@@  ::            +  . :=            - :@@@@=    :   :  @@@#
//     #@@@-   ..       #@%  ::          .**  + :#=.         .- :@@+      :      @@@=
//    .@@@@:   -        =@@*  .==-::::-=**-:-:---:=*+=--:-===: -%@.       .     -@@#
//    .@@@@-   :.       .@@@@+:  .=+=-::---......:---.:-==:  -%@@#        :    .@@#
//     #@@@*    -        #@@@@@#::....                 ...::-*@@@+       ..   .%@#
//     :@@@@.   ..      .=@@@@*  .#@@@@%+-     :   .=*%%%%*:: =@@-      ..   -@@#
//      +@@@%.         :: @@@@@+:.:-==+++**:   .  +**++++=:.-+@@@-         :#@@#
//       *@@@@-  .::::. .#@@@@@@@@@%*=-:.  ..    : .:=*%%%@@@@@@@-..:..  .*@@@*
//        *@@@@%=:...:-#@@@@@@@@@@@:                    -@@@@@@@@+:..:-+%@@@%-
//         -#@@@@@@@@@@@@#*@@@@@@@:                      :@@@@@@@@@@@@@@@%*-
//            .:-==---::  -@@@@@%.                        .%@@@@@-.:---:.
//                        =@@@@#.             .            .%@@@@-
//                        +@@@#               .              #@@@=
//                        #@@*                :               *@@+
//                        @@*                 :                #@#
//                       :@*                  -                 #@.
//                       ##                   -                  %=
//                      :%.                   -.                 .%
//                      #+                    :.                  *+
//                     -@-                    ::                  =@.
//                     *#+                    .:                  *%=
//                     +=%.                   .:                 :@=*
//                      =:*.                   :                .#=-.
//                      =  *-                             .....-#..-
//                          =%%*=---=+*****+*###***#*+==++===*%*   .
//                            .=##*=                    =+++=:
//                                :@@@@@@@@@@@@@@@@@@@@@-
//                                =@@@@@@@@@@@@@@@@@@@@@+
//                                %@@@@@@@@@@@@@@@@@@@@@@
//                               *@@@@@@@@@@@@@@@@@@@@@@@#
//                              =@@@@@@@@@@@@@@@@@@@@@@@@@*
//      _    ____  _____   _____ _    ____ ___ _   _  ____      _    ____  _____ ____
//     / \  |  _ \| ____| |  ___/ \  / ___|_ _| \ | |/ ___|    / \  |  _ \| ____/ ___|
//    / _ \ | |_) |  _|   | |_ / _ \| |    | ||  \| | |  _    / _ \ | |_) |  _| \___ \
//   / ___ \|  __/| |___  |  _/ ___ \ |___ | || |\  | |_| |  / ___ \|  __/| |___ ___) |
//  /_/   \_\_|   |_____| |_|/_/   \_\____|___|_| \_|\____| /_/   \_\_|   |_____|____/
//
/// @title ApeFacingApes
/// @author akuti.eth
/// @notice A collection of 1/1 front-facing versions of every original Bored Ape.
///         100% hand-drawn, super high-resolution, and only available to BAYC members.
///         Expanding the IP of every ape and bringing fun extensions to the community.
///         Visit https://apefacingapes.com for more information.
contract ApeFacingApes is ERC721, Ownable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    string internal constant _BASE_URI =
        "ipfs://bafybeia2a2behe3ex3tgk4pf4bdzrwzvtkx6727jgckvlbwihpngiwo64q/";
    uint256 internal constant _MAX_TOKENS_PER_TRANSACTION = 20;

    IERC721 internal constant _BAYC =
        IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    IERC20 internal constant _APE =
        IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);

    uint256 internal _mintPriceETH = 0.05 ether;
    uint256 internal _mintPriceAPE = 69 ether;

    uint256 _tokenIdCounter;

    error InvalidMintAmount();
    error InvalidValue();
    error NotSupported();

    event PersonalNote(string indexed message);

    constructor() ERC721("ApeFacingApes", "AFA") {}

    /**
     * @notice Mint ApeFacingApes to the wallet of corresponding BAYC, pay in ETH or APE.
     * @dev Mint the given tokenIds, each token is minted to the wallet of the parent token.
     * @param tokenIds A list of token ids to mint.
     * @param message An optional message, e.g., a note with a gifted token.
     */
    function mint(
        uint256[] calldata tokenIds,
        string calldata message
    ) external payable {
        uint256 nrTokens = tokenIds.length;
        if (nrTokens > _MAX_TOKENS_PER_TRANSACTION) revert InvalidMintAmount();
        if (msg.value == 0) {
            // pay with APE coin, reverts if it fails
            _APE.safeTransferFrom(
                msg.sender,
                address(this),
                _mintPriceAPE * nrTokens
            );
        } else if (msg.value != _mintPriceETH * nrTokens) {
            // pay with eth, check that it is the right amount
            revert InvalidValue();
        }
        // mint tokens to the address of the corresponding BAYC token
        _tokenIdCounter += nrTokens;
        for (uint256 i = 0; i < nrTokens; ) {
            uint256 tokenId = tokenIds[i];
            // implicit check that token exists and is not minted yet
            _mint(_BAYC.ownerOf(tokenId), tokenId);
            unchecked {
                ++i;
            }
        }
        // send message if it is included
        if (bytes(message).length > 0) emit PersonalNote(message);
    }

    /**
     * @notice Airdrop ApeFacingApes to the wallet of corresponding BAYC.
     * @dev Mint the given tokenIds, each token is minted to the wallet of the parent token.
     * @param tokenIds A list of token ids to mint.
     */
    function airdrop(uint256[] calldata tokenIds) external onlyOwner {
        uint256 nrTokens = tokenIds.length;
        // mint tokens to the address of the corresponding BAYC
        _tokenIdCounter += nrTokens;
        for (uint256 i = 0; i < nrTokens; ) {
            uint256 tokenId = tokenIds[i];
            // implicit check that token exists and is not minted yet
            _mint(_BAYC.ownerOf(tokenId), tokenId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Transfer existing ApeFacingApes to the wallet of corresponding BAYC.
     * @dev Transfer the given tokenIds to the wallet of the parent token, tokens must be minted already.
     * @param tokenIds A list of token ids to transfer.
     */
    function callToApe(uint256[] calldata tokenIds) external {
        uint256 nrTokens = tokenIds.length;
        for (uint256 i = 0; i < nrTokens; ) {
            uint256 tokenId = tokenIds[i];
            address from = ownerOf(tokenId);
            address to = _BAYC.ownerOf(tokenId);
            if (from != to) {
                _transfer(from, to, tokenId);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Withdraw the current balance.
     * @dev Withdraw the current ETH and APE balance to the defined wallets.
     */
    function withdraw() external payable {
        uint256 balanceETH = address(this).balance;
        uint256 balanceAPE = _APE.balanceOf(address(this));

        _withdrawShare(
            balanceETH,
            balanceAPE,
            0xa774A35bd1CbEadc94Ef55895a098f20DDaA25fd,
            40
        );
        _withdrawShare(
            balanceETH,
            balanceAPE,
            0x630F1895F85090aaEfea1C9E191D3f09dcb487cf,
            20
        );
        _withdrawShare(
            balanceETH,
            balanceAPE,
            0x48267141AB03cE9C3ca3FCf50B4DE5b1Ccf059a0,
            15
        );
        _withdrawShare(
            balanceETH,
            balanceAPE,
            0xF136Beb4494000bad26732dE21dB2dBEb56ee644,
            15
        );
        _withdrawShare(
            balanceETH,
            balanceAPE,
            0xf4E4B3A1cb5aF24F029950F91D1523649be0C9f8,
            7
        );
        _withdrawShare(
            balanceETH,
            balanceAPE,
            0x82fA7e296b65254bdB0C77812caDE01BAe2F8E95,
            3
        );
    }

    /**
     * @notice Update the mint price.
     * @param mintPriceETH The new mint price for one token in ETH.
     * @param mintPriceAPE The new mint price for one token in APE.
     */
    function updatePrice(
        uint256 mintPriceETH,
        uint256 mintPriceAPE
    ) external onlyOwner {
        _mintPriceETH = mintPriceETH;
        _mintPriceAPE = mintPriceAPE;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return
            string.concat(
                _BASE_URI,
                ((tokenId * 0x1b39 + 0x1a4) % 0x2710).toString(),
                ".json"
            );
    }

    // block approvals and transfers

    /**
     * @dev See {IERC721-approve}. Note that approvals are not supported by this token.
     */
    function approve(address, uint256) public virtual override {
        revert NotSupported();
    }

    /**
     * @dev See {IERC721-setApprovalForAll}. Note that approvals are not supported by this token.
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert NotSupported();
    }

    /**
     * @dev See {IERC721-transferFrom}. Note that direct transfers are not supported by this token, use {callToApe}.
     */
    function transferFrom(address, address, uint256) public virtual override {
        revert NotSupported();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Note that direct transfers are not supported by this token, use {callToApe}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert NotSupported();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Note that direct transfers are not supported by this token, use {callToApe}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override {
        revert NotSupported();
    }

    /**
     * @dev Send ETH and APE based on defined share.
     * @param totalETH the total amount of ETH to withdraw
     * @param totalAPE the total amount of APE to withdraw
     * @param to the address to send the tokens to
     * @param shares the shares for the given wallet from the total amount, assuming 100 shares total
     */
    function _withdrawShare(
        uint256 totalETH,
        uint256 totalAPE,
        address to,
        uint256 shares
    ) internal {
        uint256 paymentETH = (totalETH * shares) / 100;
        (bool success, ) = payable(to).call{value: paymentETH}("");
        require(success, "Transfer failed");
        uint256 paymentAPE = (totalAPE * shares) / 100;
        _APE.safeTransfer(to, paymentAPE);
    }
}
