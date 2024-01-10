//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC721Base.sol";

/**
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''......        .......'',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''....       .,:ccc:;,'..    ....'',,,,,,,,,,,,,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''....        .:xO0NWMMMMWWNX0koc,.    ...'',,,,,,,,,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...    .':cc..;xXWMMMMMMMMMMMMMMMNX0Oxl;.   ...'',,,,,,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,''...     .:ONWMKxkNMMMMMMMMMMMMMMMMNx,..';lxOd:.   ...'',,,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,'...     .,l0WMMMMMMMMMMMMMMMMMMMMMMMMO.     .lXMWKx:.   ..',,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,''..     .;o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMKdcc:cdkkdlcclooc,.  ..'',,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,'..     .cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0oxXWXx:'        'ldc.   ..',,,,,,,,,,,
 * ,,,,,,,,,,',,,,,,'..    .:kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.,kk,             cK0l.   ..',,,,,,,,,
 * ,,,,,,,,,,',,,,'..    .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkOKk'              .kMWKl.   ..',,,,,,,
 * ,,,,,,,,,,,,,''.    .cOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,            .,dXMMMW0,    ..',,,,,
 * ,,,,,,,,,,,',..     ,oxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkoc;,,;:coxOKNMMMMMMWk,     .',,,,
 * ,,,,,,,,,,,'..    .,oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWWWMMMMMMMMMMMMMMXx;.   ..',,
 * ,,,,,,,,,''..   .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.   .',
 * ,,,,,,,,,,..  .:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:.  .'
 * ,,,,,,,,,'.  .oNMWNWMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.  .
 * ,,,,,,,,'.   cXMNx;;c,.;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.
 * ,,,,,,,,'.  .kWKc.      .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMWO'
 * ,,,,,,,,.   ,KNl         .xW0dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXK0kxdoc;:dKWMN0xo:.  .
 * ,,,,,,,'.   cNX:          :Xk'cNMMMMMMMMMMMMMMMMMMMMWWWNXXKXNMMMMMMMMNklc:;'...         .lK0l'   .''
 * ,,,,,,,,.   ;KWk'         cXk,oNMMMMMMMWNXK0kxdolccc;,,'....c0MMMMMMM0;..                .oWWKc  .',
 * ,,,,,,,,'.  .xWWKdc,.. ..lKWX0NMMMWKkoc;'..                 cXMMMMMMMWXKO:               :KMMWk. .',
 * ,,,,''''..   'OWWKdcokO0XWMMMMMMMNd.                       .xWMMMMMW0olxX0:.           'dXMMMMk.  .,
 * ,''...        ;KWx,.,OMMMMMMMMMMMK;                        :XMMMMMNx.   'xXOc.     .'cxXWMWMW0;  .',
 * '.   .',;;;'...lNWNKXWMMMMMMMMMMMWd.                     .oXMMMMMMO'     .kWWXx:..'l0WMMNkodl.  ..''
 * .  .o0XWNNXXX0kONMMMMMMMMMMMMMMMMMWOo;,'......',.      .l0WMMMMMMWx. .;'.,OWMMMWXkdx0WNk;.    ..',''
 *   .kWMKo;'',lOXWNNWMMMMMMMMMMMMMMMMMMWNNXKKKKXNK;   .:xKWMMMMMMMMMKll0WX0XWMMMMMMMMMWO:.    ..'',,,,
 * . '0MMKo;.   .',':KMMMMMMMMMMMMMMMMMMMMMMMMMMMMNxoxkXWMMMMMMMMMMMMMWMMMMMMMMMMMMMMMKl.    ..',,,,,,,
 * . .dWMMMNl.      cNMWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,   ..'',,,,,,,,,
 * '. 'kWMMMNk:.    oWWx'.:xkOO0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'  ..',,,,,,,,,,,,
 * '.. .dXMMMMK:   .kWK;     ....';cox0XWMMMMMMMMMMMWWX0NMMMMMMMMMMMMMMMMMMMXdokkxoc.  .',,,,,,,,,,,,,,
 * ,''. .,dKWMWKx::kNXl.  .......... ..':okXWMMMMMMMX0c.cKMWX0XWMMWWNXK0Okxo;          .',,,,,,,,,,,,,,
 * ,,,'..  .:dOXXXK0d,  ..',,,,,,,,''...   .:xKWMMMMX0l..'::'..;::;,'...               .'',,,,,,,,,,,,,
 * ,,,,,''..  ..''..   .',,,,,,,,,,,,,,'.  ....cOWMMMWNKkc.  ..                         .',,,,,,,,,,,,,
 * ,,,,,,,'''.........',,,,,,,,,,,,,,,,,'. .od, .c0WMMMMMKooO000kxdlc;'..          ...   .,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.. .kXd. .kWMMMMMWMMMMMMMMMMWNXKx, ,lllodkKO,   .',,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.  .kN0ll0WMMMMMMMMMMMMMMMMMMMMWOdKMMMMMWO,    ..,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.  .xNMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMKl.     .',,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.  .oNMMXOk0WNkodkXWMMMMMMMMMMMMMMMMMMWN0:    .',,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.. .cKWk;.'kx.   'xWMMMMMMMMMMMMMMMMMMMMx.   .',,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''.  'xKKkxXx.    ,0MMMMMMMMMMMMMMMMMMMM0'   .,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.. .:dOWMO.    .OMMMMMMMMMMMMMMMMMMMMK,   .,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.   .c0Xd.   ;KMMMMMMMMMMMMMMMMMMMMk.  .',,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''..  .:xOxdxKWMMMMMMMMMMMMMMMMMMMK;  ..,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''.   'lOXWMMMMMMMMMMMMMMMMMMNk,   .',,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''..   'cx0NMMMMMMMMMMMMWKx;.  ..',,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'...   .'coxO0KK0Okdl;.   ..',,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'''...     ....      ...',,,,,,,,,,,,,,,,,,
 * ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,'.....       ...'',,,,,,,,,,,,,,,,,,,,
 * @author Augminted Labs, LLC
 */
contract ZombyWorld is ERC721Base {
    uint256 public constant MAX_RESERVED = 100;
    uint256 public reserved;

    constructor(
        address signer,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId
    )
        ERC721Base(
            "ZombyWorld",
            "ZOMBY",
            6669,
            vrfCoordinator
        )
    {
        setMintPrice(0.11 ether);
        setMaxPerAddress(2);
        setSigner(signer);

        setVrfRequestConfig(VrfRequestConfig({
            keyHash: keyHash,
            subId: subId,
            callbackGasLimit: 200000,
            requestConfirmations: 20
        }));
    }

    /**
     * @notice Mint a specified amount of tokens to a specified receiver
     * @param amount Of tokens to reserve
     * @param receiver Of reserved tokens
     */
    function reserve(uint256 amount, address receiver) external onlyOwner {
        require(totalSupply + amount <= MAX_SUPPLY, "Insufficient total supply");
        require(reserved + amount <= MAX_RESERVED, "Insufficient reserved supply");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(receiver, totalSupply);
            totalSupply += 1;
        }

        reserved += amount;
    }
}