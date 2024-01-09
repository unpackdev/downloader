pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "./base64.sol";

library ContractInfo {
    string internal constant name = "Forever Message";
    string internal constant symbol = "FMSG";
    string internal constant base_external_url = "https://forevermessage.xyz/";

    function tokenName(uint tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(name, " #", Strings.toString(tokenId)));
    }
    
    function tokenDescription(uint tokenId) public pure returns (string memory) {
        return string(abi.encodePacked("Message #", Strings.toString(tokenId)," in the Forever Message series, a collection of messages that will live forever on the Ethereum blockchain."));
    }
    
    function contractDescription() public pure returns (string memory) {
        return 'What would you say if you knew it would last forever?\\n\\nForever Message is an Ethereum-based application that allows anyone to send messages that cannot be deleted, restricted, or tampered with in any way. All of your Forever Messages will be available forever to the entire world exactly as you composed them.\\n\\nThere is no limit to the number of Forever Messages that can be sent, so send a message that lasts forever today!';
    }
    
    function tokenExternalURL(uint tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(base_external_url, Strings.toString(tokenId)));
    }
    
    function contractExternalURL() public pure returns (string memory) {
        return base_external_url;
    }
    
    function generateTokenURI(
      string[12] memory tokenAttributes
    ) public pure returns (string memory) { 
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', tokenAttributes[0], '",'
                                '"description":"', tokenAttributes[1], '",'
                                '"image_data":"', tokenAttributes[2], '",'
                                '"external_url":"', tokenAttributes[3], '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "author",',
                                            '"value": "', tokenAttributes[4], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "text_color",',
                                            '"value": "', tokenAttributes[5], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "text_length_in_bytes",',
                                            '"display_type": "number",',
                                            '"max_value": "', tokenAttributes[11], '",',
                                            '"value": "', tokenAttributes[6], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "mint_time",',
                                            '"display_type": "date",',
                                            '"value": "', tokenAttributes[9], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "text_keccak256",',
                                            '"value": "', tokenAttributes[10], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "gradient_color_one",',
                                            '"value": "', tokenAttributes[7], '"',
                                        '},'
                                        '{',
                                            '"trait_type": "gradient_color_two",',
                                            '"value": "', tokenAttributes[8], '"',
                                        '}',
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }
}