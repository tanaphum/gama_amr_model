/**
* Name: NewModel5
* Based on the internal empty template. 
* Author: Tanaphum
* Tags: 
*/


model NewModel5

/* Insert your model definition here */
global {
  map<string,rgb> state_colors <- ["N"::#green,"C"::#blue,"I"::#red,"I1"::#orange,"I2"::#maroon];
    int nb_people <- 100;
    int nb_infected <- 8;
    int nb_vectornurse <- 4;
    int nb_wash <- 4;
    float contact_distance <- 0.8#m;
    float contact_distance_nurse <- 3#m;
    int recovering_time <- 300;
    int wash_contact <- 5;
    int rest_time <- 50;
    list<geometry> room1_bounds;
    list<geometry> room2_bounds;
    int half_people;
    int count_dead <-0;
    int count_alive <-0;

    init {
        // Define room boundaries
        room1_bounds <- [rectangle({0, 0}, {50, 100})];
        room2_bounds <- [rectangle({50, 0}, {100, 100})];

        // Create room agents to visualize the boundaries
        create room number: 1 {
            location <- {25, 50};
            width <- 50;
            height <- 100;
            color <- #lightgray;
        }
        create room number: 1 {
            location <- {75, 50};
            width <- 50;
            height <- 100;
            color <- #lightgray;
        }

        // Create the common room between the two rooms
        create room number: 1 {
            location <- {50, 50};
            width <- 10;
            height <- 10;
            color <- #gray;
        }

        // Calculate the number of people in each room
        half_people <- nb_people / 2;

        // Create the 'people' agents and arrange them in the first room
        int rows1 <- floor(sqrt(half_people));
        int cols1 <- ceil(half_people / rows1);
        float spacing_x1 <- 5.5;
        float spacing_y1 <- 10.0;
        float offset_x1 <- 0.0;
        float offset_y1 <- 10.0;

        int count1 <- 0;
        loop r1 from: 0 to: rows1 - 1 {
            loop c1 from: 0 to: cols1 - 1 {
                create patient number: 1 {
                    location <- {(c1 + 1) * spacing_x1 + offset_x1, (r1 + 1) * spacing_y1 + offset_y1};
                    state <- "N";
                }
            }
        }


        // Infect a subset of the 'people' agents
        ask nb_infected among patient {
            state <- "I";
        }
        
                // Create the 'people' agents and arrange them in the second room
        int rows2 <- floor(sqrt(half_people));
        int cols2 <- ceil(half_people / rows2);
        float spacing_x2 <- 5.5;
        float spacing_y2 <- 10.0;
        float offset_x2 <- 50.0;
        float offset_y2 <- 10.0;

        int count2 <- 0;
        loop r2 from: 0 to: rows2 - 1 {
            loop c2 from: 0 to: cols2 - 1 {
                create patient number: 1 {
                    location <- {(c2 + 1) * spacing_x2 + offset_x2, (r2 + 1) * spacing_y2 + offset_y2};
                    state <- "N";
                }
            }
        }

        // Create the 'nurse' agents and assign them to rooms
        int half_nurses <- nb_vectornurse / 2;
        create nurse number: half_nurses {
            my_room <- 1;
            target <- nil;
        }
        create nurse number: half_nurses {
            my_room <- 2;
            target <- nil;
        }

        // Create the 'washroom' agents at the corners
        create washroom number: 1 {
            location <- {5, 5}; // Bottom-left corner
        }
        create washroom number: 1 {
            location <- {5, 95}; // Top-left corner
        }
        create washroom number: 1 {
            location <- {95, 5}; // Bottom-right corner
        }
        create washroom number: 1 {
            location <- {95, 95}; // Top-right corner
        }
    }
}

species room {
    float width;
    float height;
    rgb color;

    aspect default {
        draw rectangle(width, height) color: color border: #black;
    }
}

species patient {
    string state <- "N" among:["N","C","I","I1","I2"];
    int cycle_colonise;
    int cycle_infect;

    reflex contact_patient {
        ask nurse at_distance contact_distance {
            if (target = nil) {
                contact_patient <- contact_patient + 1;
                if (contact_patient >= wash_contact) {
                    washroom a <- washroom closest_to self;
                    target <- a.location;
                    contact_patient <- 0;
                }
            }

            ask nurse where (each.state="N") at_distance contact_distance {
                patient p <- any(patient);
                target <- p.location;
            }
        }
    }
    
    reflex colonise  when: state="C" {
    	if world.cycle - cycle_colonise >= recovering_time { 
           do infected;
        }        
        ask patient where (each.state="N") at_distance contact_distance {
            cycle_colonise <- world.cycle+rnd(-40,50);
            cycle_infect   <- world.cycle+cycle_colonise+rnd(-40,50);
            do colonised;
        }
        ask nurse where (each.state="N") at_distance contact_distance {
            do infected;
        }
    }

    reflex infect when: state="I" {
        ask patient where (each.state="N") at_distance contact_distance {
            cycle_colonise <- world.cycle+rnd(-40,50);
            cycle_infect   <- world.cycle+cycle_colonise+rnd(-40,50);
            do colonised;
        }
        ask nurse where (each.state="N") at_distance contact_distance {
            do infected;
        }
        if world.cycle - cycle_infect >= recovering_time { 
           do recovered;
        }
    }

    reflex infect_I1 when: state="I1" {
        ask patient where (each.state="N") at_distance contact_distance {
            cycle_colonise <- world.cycle+rnd(-40,50);
            cycle_infect   <- world.cycle+cycle_colonise+rnd(-40,50);
            do colonised;
        }
        ask nurse where (each.state="N") at_distance contact_distance {
            do infected;
        }
        if world.cycle - cycle_infect >= recovering_time/2 { 
           do recovered;
        }
    }

    reflex infect_I2 when: state="I2" {
        ask patient where (each.state="N") at_distance contact_distance {
            cycle_colonise <- world.cycle+rnd(-40,50);
            cycle_infect   <- world.cycle+cycle_colonise+rnd(-40,50);
            do colonised;
        }
        ask nurse where (each.state="N") at_distance contact_distance {
            do infected;
        }
        if world.cycle - cycle_infect >= recovering_time/6 { 
           do recovered;
        }
    }
    
    action colonised {
        state <- "C";
    }

    action infected {
        int random <- rnd(4); 

        if (random = 0) {
            state <- "I";
        }
        else if (random = 1) {
            state <- "C";
            cycle_colonise <- world.cycle+rnd(-40,50);
            cycle_infect   <- world.cycle+cycle_colonise+rnd(-40,50);
        }
        else if (random = 2) {
            state <- "N";
        }
        else if (random = 3) {
            state <- "I1";
        } else {
            state <- "I2";
        }
    }

    action recovered {
//    	count_alive <- count_alive+1;
    	if(state = "I"){
    		count_dead <- count_dead+1;
    	}else if(state = "I1" or state = "I2"){
    		int random_num <- rnd (9);
    		if(random_num <3){
    			count_alive <- count_alive+1;
    		}else{
    			count_dead <- count_dead+1;
    		}
    	}
        state <- "N";
    }

    aspect default {
        draw circle(1) color: state_colors[state];
    }
}

species nurse skills: [moving] {
    string state <- "N" among: ["N","C","I"];
    int contact_patient <- 0;
    point target;
    int my_room;
    bool go_to_common_room <- false;
    int schedule_interval <- 300; // Define the schedule interval for going to the common room
    int last_schedule_time <- 0;
    int resting;


    action infected {
        state <- "I";
    }

    action recovered {
        state <- "N";
    }
    

    reflex infect when: state="I" {
        ask patient where (each.state="N") at_distance contact_distance {
            cycle_colonise <- world.cycle+rnd(-40,50);
            cycle_infect   <- world.cycle+cycle_colonise+rnd(-40,50);
            do colonised;
        }
        ask nurse where (each.state="N") at_distance contact_distance_nurse {
            do infected;
            
        }
    }

    reflex move {
        if (world.cycle - last_schedule_time >= schedule_interval) {
            go_to_common_room <- true;
            last_schedule_time <- world.cycle;
            resting <-world.cycle;
        }

        if (go_to_common_room) {
            target <- {50, 50}; // Common room location
            
        } else {
            if (target = nil) {
                patient p <- any(patient);
                target <- p.location;
            }

            // Ensure the target is within the nurse's room boundaries
            if (my_room = 1) {
                if (target.x >= 50) {
                    target <- nil;
                }
            } else if (my_room = 2) {
                if (target.x < 50) {
                    target <- nil;
                }
            }
        }

        if (target != nil) {
            do goto target: target speed: 1.1;
        }

        if (target != nil and target distance_to self < 1#m) {
            target <- nil;
            location <- target;
            if (go_to_common_room) {
            	if(cycle-resting>=rest_time){
                go_to_common_room <- false;
                
                }
            }
        }
    }

    aspect default {
        draw circle(1) color: state="N"?#blue:#fuchsia border:#black;
        draw line(location, target);
    }
}

species washroom {
    reflex recover {
        ask nurse where (each.state="I") at_distance 6#m {
            do recovered;
        }
    }
    aspect default {
        draw square(10) color: #yellow;
    }
}


/* Insert your model definition here */

experiment testmodel type: gui {
    parameter "wash hand when contact patient" var: wash_contact min: 1 max: 10;
	parameter "recover time" var: recovering_time min: 60 max: 3600;
    output {
        display main {
            species room;
            species washroom;
            species patient;
            species nurse;
        }
        display chart {
            chart "state dynamic" type: series color: #blueviolet {
                loop stt over: ["N","C","I","I1","I2"] {
                    data stt value: patient count (each.state = stt) color: state_colors[stt];
                }
            }
        }
        display chart2 {
            chart "state dynamic" type: series color: #blueviolet {
                data "N" value: nurse count (each.state = "N") color: #blue;
                data "I" value: nurse count (each.state = "I") color: #fuchsia;
            }
        }
		display chart3{
			chart "state dynamic" type:series color:#blueviolet{
//				loop stt over:["S","I","R"]{
//					data stt value:people count (each.state=stt);
//				}
				data "Alive" value:count_alive color: #green;
				data "Dead" value:count_dead color: #red;

			}

		}
    }
}
