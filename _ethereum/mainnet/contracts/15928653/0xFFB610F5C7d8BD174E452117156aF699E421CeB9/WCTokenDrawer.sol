pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Base64.sol";

contract WCTokenDrawer  {
    string[] countries = ['Qatar','Ecuador','Senegal','Netherlands','England','Iran','USA','Wales','Argentina','Saudi Arabia','Mexico','Poland','France','Australia','Denmark','Tunisia','Spain','Costa Rica','Germany','Japan','Belgium','Canada','Morocco','Croatia','Brazil','Serbia','Switzerland','Cameroon','Portugal','Ghana','Uruguay','South Korea'];

    function buildMetadata(uint8 w1,uint8 w2,uint8 w3,uint8 w4, uint256 id, uint256 creationTime)
        external
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": WCToken prediction #',
                                Strings.toString(id),
                                '", "description": WCToken is a prediction token for the 2022 Qatar World Cup"',
                                ', "image": "',
                                "data:image/svg+xml;base64,",
                                _buildImage(w1,w2,w3,w4),
                                '", "attributes": ',
                                "[",
                                '{"trait_type": "First place",',
                                '"value":"',
                                countries[w1],
                                '"},',
                                '{"trait_type": "Second place",',
                                '"value":"',
                                countries[w2],
                                '"},',
                                '{"trait_type": "Third place",',
                                '"value":"',
                                countries[w3],
                                '"},',
                                '{"trait_type": "Forth place",',
                                '"value":"',
                                countries[w4],
                                '"},',
                                '{"trait_type": "Id",',
                                '"display_type": "number",',
                                '"value":"',
                                Strings.toString(id),
                                '"},',
                                '{"trait_type": "Mint time",',
                                '"display_type": "date",',
                                '"value":"',
                                Strings.toString(creationTime),
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function _buildImage(uint8 w1,uint8 w2,uint8 w3,uint8 w4) private view returns (string memory) {
        
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                        '<rect id="svg_11" height="100%" width="100%" y="0" x="0" fill="rgb(181,179,218)"/>',
                        '<text font-size="40" y="10%" x="5%" fill="white">',
                        countries[w1],
                        '</text>',
                        '<text font-size="40" y="30%" x="5%" fill="white">',
                        countries[w2],
                        '</text>',
                        '<text font-size="40" y="50%" x="5%" fill="white">',
                        countries[w3],
                        '</text>',
                        '<text font-size="40" y="70%" x="5%" fill="white">',
                        countries[w4],
                        '</text>',
                        "</svg>"
                    )
                )
            );
    }
}