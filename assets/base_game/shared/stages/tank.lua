function onCreatePost()
for i = 0, getProperty('stages[0].tankmanRun.length')-1 do
scaleObject('stages[0].tankmanRun.members['..i..']', 2,2)
end
end