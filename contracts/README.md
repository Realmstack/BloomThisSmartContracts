##BloomThis

This contract used to create limited no of ERC721 based NFT's.

#constructor : Intialized the contract with max no of nft's that can be minted along with default admin

#validAdmin : Check if the calling user is a valid admin or not

#modifyAdmin: You can add or remove an admin who can call write functions on this contract

#mint: It creats NFTs. In argument user has to provide recepient address and NFT json url containing various NFT attributes.

#tokenURI : returns NFT json url

#totalSupply : total supply of tokens

#mintTo : Used to mint NFT for a receiver. he has to provice token url and kind

#burn : burns a token, called by internal functions

#transferToken : internal function handles user token list, when it is transferred to another user.

#userTokens : utility function provide all the tokens owned by an user

#getFusionUrisBalance: utitily function for admin to check if he has add enough fusion token uri(s) added or not

#addFusionUris : utitily function for admin to add fusion token uri

#addFusionRule: utility function for admin to add fusion rule. where user may provide multiple token to smart contract and its burned by the contract and issues a new fusion token.

#doFusion : function called by user with token ids he owns, this will burn those provided tokens and issue a new fusion token

#claimRewards : every time a token is sold in secendary market, some royalty fee is collected in this same contract. It is then equally distributed amoung existing token owners.

#issueRewards : every time a token is sold in secendary market, some royalty fee is collected in this same contract. It is then equally distributed amoung existing token owners.
