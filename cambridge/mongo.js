// use shortbin;

db.serverStatus();

db.clicks.updateOne(
    { short_id: "abc12345", date: { $eq: new Date("2024-10-22") } },
    { $inc: { "clicks": 2, "countries.UK": 2, "referers.gwthm": 1 } },
    { upsert: true }
);

db.clicks.createIndex({ short_id: 1, date: 1 }, { unique: true });

db.clicks.aggregate([
    {
        $match: {
            short_id: "abc12345",
            date: { $gte: new Date("2024-10-21"), $lte: new Date("2024-10-22") }
        }
    },
    {
        $addFields: {
            country: { $objectToArray: "$countries" },
            referer: { $objectToArray: "$referers" }
        }
    },
    {
        $facet: {
            clicks: [
                {
                    $group: {
                        _id: "$short_id",
                        clicks: { $sum: "$clicks" }
                    }
                }
            ],
            countries: [
                { $unwind: "$country" },
                {
                    $group: {
                        _id: {
                            short_id: "$short_id",
                            countryKey: "$country.k"
                        },
                        value: { $sum: "$country.v" }
                    }
                },
                {
                    $project: {
                        k: "$_id.countryKey",
                        v: "$value"
                    }
                },
                {
                    $group: {
                        _id: "$_id.short_id",
                        countries: { $push: { k: "$k", v: "$v" } }
                    }
                },
                {
                    $project: {
                        countries: { $arrayToObject: "$countries" }
                    }
                }
            ],
            referers: [
                { $unwind: "$referer" },
                {
                    $group: {
                        _id: {
                            short_id: "$short_id",
                            refererKey: "$referer.k"
                        },
                        value: { $sum: "$referer.v" }
                    }
                },
                {
                    $project: {
                        k: "$_id.refererKey",
                        v: "$value"
                    }
                },
                {
                    $group: {
                        _id: "$_id.short_id",
                        referers: { $push: { k: "$k", v: "$v" } }
                    }
                },
                {
                    $project: {
                        referers: { $arrayToObject: "$referers" }
                    }
                }
            ]
        }
    },
    {
        $project: {
            clicks: { $arrayElemAt: ["$clicks.clicks", 0] },
            countries: { $arrayElemAt: ["$countries.countries", 0] },
            referers: { $arrayElemAt: ["$referers.referers", 0] }
        }
    }
]);


db.runCommand(
    {
        explain: { count: "clicks", query: { clicks: { $gt: 4 } } },
        verbosity: "queryPlanner"
    }
);


db.currentOp(true).inprog.reduce(
    (accumulator, connection) => {
        ipaddress = connection.client ? connection.client.split(":")[0] : "Internal";
        accumulator[ipaddress] = (accumulator[ipaddress] || 0) + 1;
        accumulator["TOTAL_CONNECTION_COUNT"]++;
        return accumulator;
    },
    { TOTAL_CONNECTION_COUNT: 0 }
)