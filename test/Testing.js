const { expectRevert,expectEvent } = require("@openzeppelin/test-helpers");

const UserContract = artifacts.require("./UserContract.sol");
const Ballot = artifacts.require("./Ballot.sol");
const VoterList = artifacts.require("./VoterList.sol");

contract ("Ballot", function(accounts){
    let userContractInstance1,userContractInstance2,ballotInstance,voterListInstance;
    const [user1,user2,user3,access1,access2,admin,_] = accounts;

    before("initialization",async()=>{
        userContractInstance1 = await UserContract.new("SAM","M",40,{from:user1});
        userContractInstance2 = await UserContract.new("Allen","M",36,{from:user2});
        voterListInstance = await VoterList.new({from:admin});        
        console.log("address",voterListInstance.address);
        ballotInstance = await Ballot.new(864000,voterListInstance.address,{from:admin});
    });

    it("should correct give the details of the user1", async()=>{
        let details = await userContractInstance1.getDetails({from:user1});
        assert(details.name === "SAM");
        //other details can be fethced similarly
    });
    it("should give error while fetching details if no access given", async()=>{
        await expectRevert(
            userContractInstance1.getDetails({from:user2}),
            "no access to get details"
        );
    });

    it("user contract should allow access control", async()=>{
        //user1 will give access control to admin
        let receipt = await userContractInstance1.giveAccess(admin,864000,{from:user1});
        let receipt2 = await userContractInstance2.giveAccess(admin,864000,{from:user2});
        
        //now admin should be able to get details of user1
        let data = await userContractInstance1.getDetails({from:admin});        
        assert(data.name==="SAM");
    });

    context("VoterList Testing", ()=>{

        it("should allow to add voters", async()=>{
            await Promise.all([
                voterListInstance.addVoter(user1,{from:admin}),
                voterListInstance.addVoter(user2,{from:admin}),
                voterListInstance.addVoter(user3,{from:admin}),
            ]);
            
            let voters = await voterListInstance.getVoters();            
            assert(voters[0]===user1);
            assert(voters[1]===user2);
        });

        it("should not allow non-admins to add voters", async()=>{
            await expectRevert(
                voterListInstance.addVoter(user3,{from:user1}),
                "only owner can call"
            );
        });

        it("should allow to set user contract and respective smart contract", async()=>{
            await voterListInstance.initUserContract(user1,userContractInstance1.address,{from:admin});
            await voterListInstance.initUserContract(user2,userContractInstance2.address,{from:admin});

            let contractAddress1 = await voterListInstance.getUserContractAddress(user1);
            let contractAddress2 = await voterListInstance.getUserContractAddress(user2);

            assert(contractAddress1===userContractInstance1.address);
            assert(contractAddress2===userContractInstance2.address);
        });

        it("should get user details via contract address", async()=>{
            let contractAddress2 = await voterListInstance.getUserContractAddress(user2);
            let data = await voterListInstance.getUserDetails(contractAddress2,{from:admin});            
            assert(data.name==="Allen");
        });

        it("should allow to check if voter is registered or not", async()=>{
            let isReg = await voterListInstance.isRegistered({from:user1});
            assert(isReg===true);
        });

    });

    context("Ballot Voting Testing", ()=>{

        it("should allow adding candidates", async()=>{
            let candidates = ["Cand1","Cand2","Cand3","Cand4"];
            await ballotInstance.addCandidates(candidates,{from:admin});
            let candidate = await ballotInstance.getCandidate(0);
            assert(candidate.name==="Cand1");
        });

        it("should allow to add voters", async()=>{
            await ballotInstance.addVoters([user1,user2,user3],{from:admin});
        });

        it("should not allow to cast vote if not a voter", async()=>{
            await expectRevert(
                ballotInstance.castVote(0,{from:access1}),
                "The address is not a voter"
            );            
        });

        it("should allow to cast vote if a voter", async()=>{
            await ballotInstance.castVote(0,{from:user1});
            await ballotInstance.castVote(1,{from:user2});
            await ballotInstance.castVote(2,{from:user3});

            let votedFor1 = await ballotInstance.getMyVote({from:user1});
            assert(votedFor1.eq(0));
        });

        //many more tests need to run..Truffle started giving "out of Gas" issues while running these tests

    });


});