// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Sacramento Kings
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";

import "./ERC165Checker.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                           ╦                                             //
//                         ╔╬╬                                             //
//                        ╔╬╣  ╔╗                   ╔╗  ╦╦╦    ╔╬╬╗        //
//                ╔╦╬   ╔╬╬╬╬  ╬╬         ╔╬╬╗   ╔╬╬╬╬╬╬╬╣   ╔╬╬╬╬╬        //
//            ╔╦╬╬╬╬╝  ╔╬╬╬╬╝       ╔╦╬╦╬╬╬╬╬╣  ╔╬╬╩  ╬╬╬╝ ╦╬╬╩ ╠╬╬╣       //
//           ╠╬╬╬╬╬╬  ╬╬╬╬╩   ╔╦╬   ╬╬╬╬╝ ╠╬╬  ╔╬╬╣  ╬╬╬╣╔╬╬╩   ╠╬╬╣       //
//           ╚╩╩╬╬╬╬╦╬╬╬╩     ╠╬╬  ╠╬╬╝   ╬╬╣ ╔╬╬╬╬╦╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬    //
//              ╬╬╬╬╬╬╝      ╠╬╬╝  ╬╬╣   ╠╬╬╬╬╩╩╬╬╬╩╬╬╬╬╩   ╚╩╩╩╩╩  ╬╬╬╬   //
//              ╬╬╬╬╬╣       ╠╬╬   ╬╬╣   ╚╬╩╩      ╬╬╬╬╗      ╔╦╦╦╬╬╬╝╙    //
//             ╬╬╬╣╬╬╬╬╦    ╔╦╬╬╦╦╦╬╬╝      ╔╦╦╬╬╬╬╬╬╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩       //
//             ╠╬╬╝ ╬╬╬╬╬╦╦╬╬╩╬╬╬╩╩╩   ╔╦╬╬╩╩╬╬╬╬╝╠╬╬⌐                     //
//             ╬╬╬   ╙╬╬╬╬╬╬╝     ╔╦╦╬╬╬╩╝ ╔╬╬╬╩╝╔╬╬╝                      //
//            ╬╬╬╣           ╔╦╦╬╬╬╬╩╝    ╔╬╬╬╝ ╔╬╬╩                       //
//      ╬    ╬╬╬╬╝        ╔╦╬╬╬╬╬╬╩      ╔╬╬╬╬╦╦╬╬╩                        //
//      ╬╦╦╦╬╬╬╬╝     ╔╦╬╬╬╬╬╬╬╩╩        ╬╬╬╬╬╬╬╬╝                         //
//      ╚╬╬╬╬╬╬╩    ╔╬╬╬╬╬╬╬╬╩            ╚╩╩╩╝                            //
//       ╚╩╩╩╩╝   ╔╦╬╬╬╬╬╬╬╝                                               //
//             ╔╬╬╬╬╬╬╬╬╬╬╩                                                //
//           ╔╬╬╬╬╬╬╬╬╩╩╩╝                                                 //
//         ╔╬╬╬╬╬╩╩╝                                                       //
//       ╔╬╬╬╩╩                                                            //
//      ╬╬╩╝                                                               //
//    ╩╩╝                                                                  //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * 1985 Inaugural Season Opening Night Pin – Special Edition
 */
contract KingsPins is AdminControl {

     address private _creator;    

    /**
     * @dev Activate the contract and mint the tokens
     */
    function activate(address creator) public adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "Requires creator to implement IERC721CreatorCore");
        require(_creator == address(0), "Already active");

        _creator = creator;

        string[84] memory hashes = [
            "mdx21f5lP3vDFzRySV8m4n5kd3E_vXGmaHSs2uC6NcQ",
            "SOXmBqJDWYYzyzcuY2Kssof6TpS4gC7ZY2mKY9h-D_E",
            "oUewfazRxNNyFOF-MTZECu6brW9BIDPW38akY9CbtOg",
            "agLZK3myhunlyY3oX4vL_GWAbtm2R6FzpLb3q8WUKxE",
            "wmA4g9EQZD3mfLt7QnrG5GcJpV5Sloea0QlyCvuBhQw",
            "Z6ptejLWEwZjNT6tHl3uKRUgZ_3yeNtpRn28mzHZyCg",
            "sRfnvi-41Pb5qsq0fywBAT6iaehdVqQidqozVqj1tSs",
            "qozuGWkw1_crmcyoeDOE7zdmXCb_9Hq9kQYx4LSXN08",
            "ZJOEfx5HIjGsvNWrG7VZ-1CRfhBhhDepGiQGHQRnPq8",
            "pog4NmGp1Ft1xsrdDhzxDU84qSsDh3Lz34zqQcmct3M",
            "vXlw0JsstKkkRA92wBbXjtxkSBu33OvL6mbsKXNSU8c",
            "CsQf0akwjdOfbvfXSMk782sCNhUIfo5rB0ZLDWE3mwI",
            "UY1XlH9S7BgtL9ZcRjo2wOyLchqmY0fpLbwHmIZqG6Q",
            "ozexV0CN3QLpF9r9RZ0quezpq6bQA_xcPAuicWW7AQ8",
            "HDe3kEWjN9EQQG5TlyMO60bPg0dxBOR6Yqun-CNhpx0",
            "IzkQnUXJzRTClJpxBsWJl0VeQrcJFzDifG3-eStcLFM",
            "QhyXNYUcH6RQSmP2yU0Kh-xUB3A6RjGgRrBOstL8CCU",
            "lzcZkaaGDFawPLOgleAI5ogcUZ2UEzvUHFvKj1cWA8U",
            "LgOfDu3bBGdkyoVEk1-K6FsCfyt0qE-8d-WZkGqiDFE",
            "SboO2zUhhPVNNjf3XJr5fAjpLt-qr85DZVBfT2rk5_s",
            "yRz-W0hcua6K97lQVS1nU1gXuVdpMGf7H4DRqNwd3jQ",
            "D1tqlNS4IW1fTWbJk9Av5o2cUYYZ7ccjhlKhSLbs7VQ",
            "TUQ3kIiy_90zWrCoRTgZg8_Z6w7RhT9Xpw8m6NjW6BM",
            "jPCGRcOHGPMa7PMHRcA7BGkn1uzR14Sb0nHYj7AWHXc",
            "pK2h971pmK8VX0VZXRCOxcSz_Q01enG7kVK4zF8LE2U",
            "VytCFcGwCWsnKcuNt4-sg1rfT8p9EMp5Gh3x82zlkSU",
            "LnZJ2rrtkpZ71mTmojpFr1IeeM9H7yi9l0zafiJe8j4",
            "UQKqAsuJtJiUjbZXVVXVPAqRbQtzFVBOz8FoXPPCnPM",
            "LvVPcUqUKC-VFdRQoH3q3IDmkkpxEMA9N6Mc0Tgz3wY",
            "L4Lh3dbvA328-ovkQB26LQanf7-2zlBRUA9feMB7_Ng",
            "hQzYWTUz4QuZ26kh4kBEcpVDG4OcyPDJO9Fv3tFzWFc",
            "ilmMA17sY16MY_1PgFet5lxKnVZwt18xBhMMJq93yro",
            "nLh_pKaL6fhXU5-3bUFLI3KpqBhWOTQqk6eHFNKou1k",
            "-rnLyIIjPZyNMwvlszGh2hH3meLzRGSfLMtGBvOUcRE",
            "xrAHdW3wHoKH4uacxwYtHGEH9CN-1Ihracqk1CBeVWk",
            "HJl4P1mdLzF5fTtSpFu_rQsnpvsrJ3zdfqjcPJSq8AM",
            "95fgRJeGDEZboPEbsPwcYpUyKU6CNajwd03KjIah918",
            "1q249yW3WXWCIcSAHqTF4A4f14iXcagNAhIFI97GtJs",
            "fxgTQMiFr-GLuoeezhkFn1QxAqGYW7pJ6vsV-RNo2so",
            "ejF7a8Z_DBCZKub_A3i_R-QoSOmrqBnNDYpJsjt6blQ",
            "r2ZJrskXgMrRVne5fPeDIG1qhcZ0Pdo8OmXXybUYveM",
            "E-tz4u0zAFUoLHGuRujKg4T5k35_DLoRs01ae2vvYKI",
            "2g_wvMtl8DLB0Lxg6kkwBVPQYjt9eaZbPQa1SYPpvyQ",
            "iNL86xE8kNNb3L7j-ztmUxOFDio_RCpd6CjlpiHFLOo",
            "3CCHaY7wtlcd8imSAL-FsR0PTOkfdBuziOQX7BVk-14",
            "Vv47URPO7SidofsYzjwiKFrQNK6AXLJdTXxtwLTx6MI",
            "wB-y3l9TSy67uGecnMVXNhVcG0sNSUt2oCh_t_YtZJ8",
            "HWFIDPA2nkU4B-ybcAOc-KFB5V2KrtxpODUMPINZwGg",
            "iEggRcgXyL_mvjqwZfiRpQ4W0_XO4agCpAQ9_bduQUc",
            "_avn1n9J4TIccU4p_rPqVFOyL-agfPUYsTNeqPUnNbg",
            "OO60BJn1QB7G-QxLT2sE7ds_BkOBuahyq9HzGQeCkao",
            "uJETazKkdSpqKiPHoP43gpedG9yavmG2Un-m0UG9v1g",
            "spFC7BpOrV5UpQP1fjDdMxLqmLC_3sypntya9fhampA",
            "z2JFW6jcx4ak2DmZfDkEidI3NIaGeRiZGJ9XROIA5sY",
            "uW1mCRhq1B3VRPDFEE3nFJUkdsmwTvrVbE-UT6pxtok",
            "2XbHUb2b3S8JZDQbm8Utjg5i3QI0-_hWsBL1s5ha9Ms",
            "nQKVftnCU5VrnMhSaLLEEgtoYWcGvhAKt7ZYqVelqmw",
            "j13eXYze9rFjrFZyAMQlMqQXC7K3rNz9hEYk7I3pU0M",
            "crFpfFSa4vfDQStuDYdq2O46EP8zxpUa_2ZFBr7LT2s",
            "bJR_4VLv-hWU7TSpqCUs1ezau0cfv4ARE66UoMbsyQk",
            "87o5zQ026hMK9juFHhiUByqHLDd1i4F_Bz79C7ne1FE",
            "AMtn4SRcyvNPFkCelwNvtntBfUHqfnn4EINJtDSY3KU",
            "NPT1nusPvmOfsyivNpNLQitHi6zlueI6G1RZbnoMp28",
            "lS6TIurSukGM92DsfxoUu8Dxoy_atIrCoi3XseZqQ2w",
            "JAxNwYrk_C502jTomeMzo8otjfO8KYS2_g9gFV13oZA",
            "Yf9KFqrhIZ2ohbeQHcRjSwfxL4Oa2jwZwSKtRrSUY0M",
            "Mc_TZRzkia8O5vbeEFi5To45npGtbHFTgMY6UiZjnl4",
            "p19iD1c4YOwXni7-ZbLcih08beehQVJQGBCohphuBcA",
            "pUAI-F78fTw-DsLxzg1FaIKKIaz_E10QbPHxq9aKe14",
            "tvNoAKXPgA0f-wgRqdlH93MbutjWyIe1U81Cw_3akMQ",
            "fPrUWMNosaLuUKOO-C_X1I_UCilAkbZPvd72oQKnI9s",
            "Ac1uUb4yi7fT9MmaXawTSjyUdl918pQTmvaKVBgSX_c",
            "ujNxT3qtdfMRW6yKhxF15sJqv1LSnz78UnR3qPCEXVM",
            "Tkc0WtgFjUoQ9oGdLKMgNz4e2Np5R8amFnwp0OVVzqM",
            "SbtNPpyKLaFbchmP4SEe9rxpcPNoP3nlqGOv8SYMu24",
            "JfrJAN-ngDUbGwkNnVff8qfDkMsZ4gGtBrHG-5r5_7M",
            "o_I9Ghne2X8DhZOjp_S7vyE9KN1FfNeuW_bvfOr7NnQ",
            "oz6V2bC-PVfDAtIJTiYB8BAyxDAN4RJmRLeC14emA40",
            "McDLNHSEIm6uZPaeyOwl_xiNbUO_4OPit6thjKpg7Wg",
            "o3k_-F8pGP-v6AIv-jTPgz2Givr7xJeWMSTbXoUlj8Q",
            "QgZwFC5wuKIJ3Pv_3CTmxkdc705ENM8_5lNd7Qxmxk8",
            "2JnlggtDmkc9H9KTmCK9Tj-rjKoDTyOrAIiyAFLvmwE",
            "-9zCHYC3UD4QASu1eloANMXoBAsiF8DmQqKprmAaNx4",
            "eWVXQ3AqLbZaSgwskenkloejJ43X9JhlsUXcXvSy_Ss"];

        IERC721CreatorCore(_creator).setTokenURIPrefixExtension('https://arweave.net/');
        for (uint i = 0; i < hashes.length; i++) {
            IERC721CreatorCore(_creator).mintExtension(owner(), hashes[i]);
        }
    }

    function setBaseTokenURI(string calldata uri) external adminRequired {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(uri);
    }

    function setBaseTokenURI(string calldata uri, bool identical) external adminRequired {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(uri, identical);
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIExtension(tokenId, uri);
    }

    function setTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIExtension(tokenIds, uris);
    }

    function setTokenURIPrefix(string calldata prefix) external adminRequired {
        IERC721CreatorCore(_creator).setTokenURIPrefixExtension(prefix);
    }


}