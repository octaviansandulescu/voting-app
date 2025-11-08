async function vote(choice) {
    try {
        const response = await fetch('http://localhost:8000/vote', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ choice: choice })
        });
        updateResults();
    } catch (error) {
        console.error('Error voting:', error);
    }
}

async function updateResults() {
    try {
        const response = await fetch('http://localhost:8000/results');
        const data = await response.json();
        document.getElementById('dog-votes').textContent = data.dogs;
        document.getElementById('cat-votes').textContent = data.cats;
    } catch (error) {
        console.error('Error fetching results:', error);
    }
}

// Update results every 2 seconds
setInterval(updateResults, 2000);
updateResults();
